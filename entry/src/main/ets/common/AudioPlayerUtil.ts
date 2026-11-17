import media from '@ohos.multimedia.media'
import { BusinessError } from '@ohos.base'

// 歌曲数据结构
export interface SongItem {
  name: string
  artist: string
  duration: number // 秒
  cover?: ResourceStr // 封面图
  url?: string // 音频URL（网络音频）
  rawfile?: string // rawfile文件名（本地mp3，如 'mp3.mp3'）
}

// 播放模式
export enum PlayMode {
  ListLoop = 0,  // 列表循环
  SingleLoop = 1, // 单曲循环
  Shuffle = 2,    // 随机播放
  Sequential = 3  // 顺序播放
}

// 播放器状态（全局单例）
class AudioPlayerState {
  // 全局播放列表；初始为空，所有带 MiniPlayer 的页面共享
  playlist: SongItem[] = []
  currentIndex: number = -1
  // 播放状态
  isPlaying: boolean = false
  currentTime: number = 0
  duration: number = 0
  playMode: PlayMode = PlayMode.ListLoop
  // 收藏
  favorites: Set<string> = new Set<string>()
  favoriteSongs: SongItem[] = []
  // avplayer实例
  private avPlayer?: media.AVPlayer
  private timer?: number
  private seekLockCount: number = 0
  // 订阅者回调
  private listeners: Array<() => void> = []
  // 存储context用于playCurrent里读rawfile
  ctx: object | null = null

  initContext(ctx: object): void {
    this.ctx = ctx
  }

  // 注册UI刷新回调
  subscribe(callback: () => void): void {
    this.listeners.push(callback)
  }

  unsubscribe(callback: () => void): void {
    this.listeners = this.listeners.filter(cb => cb !== callback)
  }

  private notify(): void {
    for (const cb of this.listeners) {
      cb()
    }
  }

  // 判断歌曲是否已收藏
  isFavorite(songName: string): boolean {
    return this.favorites.has(songName)
  }

  // 切换收藏状态
  toggleFavorite(song: SongItem): void {
    if (this.favorites.has(song.name)) {
      this.favorites.delete(song.name)
      this.favoriteSongs = this.favoriteSongs.filter(s => s.name !== song.name)
    } else {
      this.favorites.add(song.name)
      this.favoriteSongs.push(song)
    }
    this.notify()
  }

  // 收藏当前歌曲
  toggleCurrentFavorite(): void {
    const song = this.currentSong
    if (song) {
      this.toggleFavorite(song)
    }
  }

  // 当前歌曲是否已收藏
  get isCurrentFavorite(): boolean {
    const song = this.currentSong
    return song ? this.favorites.has(song.name) : false
  }

  private handlePlaybackError(source: string, error?: BusinessError): void {
    this.isPlaying = false
    this.stopTimer()
    if (error) {
      console.error(`${source} error: code=${error.code}, message=${error.message}`)
    } else {
      console.error(`${source} entered error state`)
    }
    this.notify()
  }

  // 使用 AVPlayer 原生事件更新进度；部分设备在播放时直接读取 currentTime 会返回无效值
  private bindProgressEvents(): void {
    if (!this.avPlayer) return
    this.avPlayer.off('timeUpdate')
    this.avPlayer.off('durationUpdate')
    this.avPlayer.on('timeUpdate', (timeMs: number) => {
      const seconds = timeMs / 1000
      if (Number.isFinite(seconds) && seconds >= 0) {
        this.currentTime = seconds
        this.notify()
      }
    })
    this.avPlayer.on('durationUpdate', (durationMs: number) => {
      const seconds = durationMs / 1000
      if (Number.isFinite(seconds) && seconds > 0) {
        this.duration = seconds
        this.notify()
      }
    })
  }

  // 设置歌单并播放
  async setPlaylist(list: SongItem[], startIndex: number): Promise<void> {
    this.playlist = [...list]
    this.currentIndex = startIndex
    this.currentTime = 0
    this.notify()
    await this.playCurrent()
  }

  // 新添加的歌曲始终置顶；立即播放时切到新歌，静默添加时保持当前歌曲不变
  async addSong(song: SongItem, playNow: boolean): Promise<void> {
    this.playlist.unshift(song)
    if (playNow) {
      this.stopTimer()
      this.currentIndex = 0
      this.currentTime = 0
      this.notify()
      await this.playCurrent()
    } else {
      if (this.currentIndex >= 0) {
        // 队首插入后修正索引，使正在播放的歌曲保持不变
        this.currentIndex++
      }
      this.notify()
    }
  }

  // 批量静默添加到队首，不中断当前播放，并保留歌单传入顺序
  addAllSongs(songs: SongItem[]): void {
    if (songs.length === 0) return
    this.playlist = [...songs, ...this.playlist]
    if (this.currentIndex >= 0) {
      this.currentIndex += songs.length
    }
    this.notify()
  }

  // “播放全部”：用当前歌单替换播放列表，并从歌单第一首开始播放
  async replaceAndPlayAll(songs: SongItem[]): Promise<void> {
    if (songs.length === 0) {
      await this.clearPlaylist()
      return
    }
    this.playlist = [...songs]
    this.currentIndex = 0
    this.currentTime = 0
    this.stopTimer()
    this.notify()
    await this.playCurrent()
  }

  // 删除播放列表中指定位置的歌曲
  async removeSong(index: number): Promise<void> {
    if (index < 0 || index >= this.playlist.length) return
    const wasCurrent = index === this.currentIndex
    this.playlist.splice(index, 1)
    if (this.playlist.length === 0) {
      this.currentIndex = -1
      this.isPlaying = false
      this.stopTimer()
      if (this.avPlayer) { await this.avPlayer.reset() }
    } else if (index < this.currentIndex) {
      this.currentIndex--
    } else if (wasCurrent) {
      if (this.currentIndex >= this.playlist.length) {
        this.currentIndex = this.playlist.length - 1
      }
      this.stopTimer()
      this.currentTime = 0
      await this.playCurrent()
    }
    this.notify()
  }

  // 清空播放列表
  async clearPlaylist(): Promise<void> {
    this.playlist = []
    this.currentIndex = -1
    this.isPlaying = false
    this.stopTimer()
    if (this.avPlayer) { await this.avPlayer.reset() }
    this.notify()
  }

  // 播放列表中指定位置的歌曲
  async playAtIndex(index: number): Promise<void> {
    if (index < 0 || index >= this.playlist.length) return
    this.currentIndex = index
    this.stopTimer()
    this.currentTime = 0
    this.notify()
    await this.playCurrent()
  }

  // rawfile播放：RawFileDescriptor在外部读好传入
  async playFd(list: SongItem[], startIndex: number, rawFd: media.AVFileDescriptor): Promise<void> {
    console.log('playFd 入口, index=' + startIndex + ', fd=' + rawFd.fd)
    this.playlist = list
    this.currentIndex = startIndex
    if (!this.avPlayer) {
      console.log('playFd 新建avPlayer')
      this.avPlayer = await media.createAVPlayer()
    } else {
      console.log('playFd reset旧avPlayer')
      await this.avPlayer.reset()
    }
    this.bindProgressEvents()
    console.log('playFd avPlayer就绪, 注册stateChange监听')
    // 状态监听：idle → initialized → prepared → playing
    this.avPlayer.off('stateChange')
    this.avPlayer.on('stateChange', (state: media.AVPlayerState) => {
      console.log('playFd stateChange: ' + state)
      if (state === 'initialized') {
        console.log('playFd → prepare()')
        this.avPlayer?.prepare()
      } else if (state === 'prepared') {
        console.log('playFd → play()')
        const actualDuration = Math.floor((this.avPlayer?.duration ?? 0) / 1000)
        if (actualDuration > 0) { this.duration = actualDuration }
        this.avPlayer?.play()
        this.isPlaying = true
        this.startTimer()
        this.notify()
      } else if (state === 'error') {
        console.log('playFd stateChange error! 文件解码失败')
      } else if (state === 'completed') {
        console.log('playFd 播放完毕')
        this.onSongEnd()
      }
    })
    console.log('playFd 设置fdSrc')
    this.avPlayer.fdSrc = rawFd  // 触发 idle → initialized
  }

  // 播放当前歌曲
  async playCurrent(): Promise<void> {
    if (this.currentIndex < 0 || this.currentIndex >= this.playlist.length) return
    const song = this.playlist[this.currentIndex]
    this.duration = song.duration

    // rawfile 播放
    if (song.rawfile && this.ctx) {
      try {
        console.log('playCurrent rawfile=' + song.rawfile)
        const rm = (this.ctx as Record<string, Object>)['resourceManager'] as Record<string, Function>
        const rawFd = rm.getRawFdSync(song.rawfile) as media.AVFileDescriptor
        console.log('playCurrent getRawFdSync ok, fd=' + rawFd.fd)

        if (!this.avPlayer) {
          this.avPlayer = await media.createAVPlayer()
        } else {
          await this.avPlayer.reset()
        }
        this.bindProgressEvents()
        this.avPlayer.off('stateChange')
        this.avPlayer.on('stateChange', (state: media.AVPlayerState) => {
          console.log('playCurrent stateChange: ' + state)
          if (state === 'initialized') {
            this.avPlayer?.prepare()
          } else if (state === 'prepared') {
            const actualDuration = Math.floor((this.avPlayer?.duration ?? 0) / 1000)
            if (actualDuration > 0) { this.duration = actualDuration }
            this.avPlayer?.play()
            this.isPlaying = true
            this.startTimer()
            this.notify()
          } else if (state === 'error') {
            console.log('playCurrent stateChange error!')
          } else if (state === 'completed') {
            console.log('playCurrent rawfile 播放完毕')
            this.onSongEnd()
          }
        })
        this.avPlayer.fdSrc = rawFd
        return
      } catch (e) {
        console.log('playCurrent rawfile失败: ' + JSON.stringify(e))
      }
    }

    // 播放网络音频（url）
    if (song.url) {
      this.isPlaying = false
      this.currentTime = 0
      this.stopTimer()
      this.notify()
      if (!this.avPlayer) {
        this.avPlayer = await media.createAVPlayer()
      } else {
        await this.avPlayer.reset()
      }
      this.bindProgressEvents()
      this.avPlayer.off('stateChange')
      this.avPlayer.off('error')
      this.avPlayer.on('error', (error: BusinessError) => {
        this.handlePlaybackError('playCurrent url', error)
      })
      this.avPlayer.on('stateChange', (state: media.AVPlayerState) => {
        console.log('playCurrent url stateChange: ' + state)
        if (state === 'initialized') {
          this.avPlayer?.prepare().catch((error: BusinessError) => {
            this.handlePlaybackError('playCurrent url prepare', error)
          })
        } else if (state === 'prepared') {
          const actualDuration = Math.floor((this.avPlayer?.duration ?? 0) / 1000)
          if (actualDuration > 0) { this.duration = actualDuration }
          this.avPlayer?.play().then(() => {
            this.isPlaying = true
            this.startTimer()
            this.notify()
          }).catch((error: BusinessError) => {
            this.handlePlaybackError('playCurrent url play', error)
          })
        } else if (state === 'error') {
          this.handlePlaybackError('playCurrent url stateChange')
        } else if (state === 'completed') {
          console.log('playCurrent url 播放完毕')
          this.onSongEnd()
        }
      })
      console.log('playCurrent url source: ' + song.url)
      this.avPlayer.url = song.url
      return
    }
  }

  private startTimer(): void {
    this.stopTimer()
    this.timer = setInterval(() => {
      if (this.avPlayer && this.isPlaying) {
        if (this.seekLockCount > 0) { this.seekLockCount--; return }
        const mediaTime = this.avPlayer.currentTime / 1000
        if (Number.isFinite(mediaTime) && mediaTime >= 0) {
          this.currentTime = mediaTime
          this.notify()
        }
      }
    }, 250)
  }

  private stopTimer(): void {
    if (this.timer !== undefined) {
      clearInterval(this.timer)
      this.timer = undefined
    }
  }

  // 播放/暂停
  togglePlay(): void {
    if (this.currentIndex < 0) return
    if (this.isPlaying) {
      this.isPlaying = false
      this.stopTimer()
      if (this.avPlayer) {
        this.avPlayer.pause()
      }
    } else {
      if (this.avPlayer) {
        this.isPlaying = true
        this.avPlayer.play()
        this.startTimer()
      }
    }
    this.notify()
  }

  // 歌曲自然播放完毕
  private onSongEnd(): void {
    if (this.playMode === PlayMode.SingleLoop) {
      // 单曲循环：自动结束才从头循环
      this.currentTime = 0
      this.playCurrent()
      return
    }
    this.next()
  }

  // 下一曲（手动点击）
  next(): void {
    if (this.playlist.length === 0) return
    console.log('next 当前index=' + this.currentIndex)
    this.stopTimer()
    switch (this.playMode) {
      case PlayMode.Shuffle:
        this.currentIndex = Math.floor(Math.random() * this.playlist.length)
        break
      case PlayMode.SingleLoop:
        // 单曲循环下手动按：切换到下一首
        this.currentIndex = (this.currentIndex + 1) % this.playlist.length
        break
      default:
        this.currentIndex = (this.currentIndex + 1) % this.playlist.length
        break
    }
    this.playCurrent()
  }

  // 上一曲
  prev(): void {
    if (this.playlist.length === 0) return
    this.stopTimer()
    if (this.currentTime > 3) {
      // 当前播放超过3秒，从头开始
      this.playCurrent()
      return
    }
    if (this.currentIndex <= 0) {
      this.currentIndex = this.playlist.length - 1
    } else {
      this.currentIndex--
    }
    this.playCurrent()
  }

  // 跳转到指定位置
  seekTo(seconds: number): void {
    this.currentTime = Math.min(seconds, this.duration)
    this.seekLockCount = 5 // 5 × 250ms = 1.25s 内阻止定时器回写旧进度
    if (this.avPlayer) {
      this.avPlayer.seek(seconds * 1000, media.SeekMode.SEEK_PREV_SYNC)
    }
    this.notify()
  }

  // 切换播放模式
  cycleMode(): void {
    const modes = [PlayMode.ListLoop, PlayMode.SingleLoop, PlayMode.Shuffle, PlayMode.Sequential]
    const idx = modes.indexOf(this.playMode)
    this.playMode = modes[(idx + 1) % modes.length]
    this.notify()
  }

  getModeLabel(): string {
    switch (this.playMode) {
      case PlayMode.ListLoop: return '列表循环'
      case PlayMode.SingleLoop: return '单曲循环'
      case PlayMode.Shuffle: return '随机播放'
      case PlayMode.Sequential: return '顺序播放'
    }
  }

  // 格式化时间 mm:ss
  formatTime(seconds: number): string {
    const safeSeconds = Number.isFinite(seconds) && seconds >= 0 ? seconds : 0
    const m = Math.floor(safeSeconds / 60)
    const s = Math.floor(safeSeconds % 60)
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`
  }

  // 是否正在播放
  get hasSong(): boolean {
    return this.currentIndex >= 0 && this.currentIndex < this.playlist.length
  }

  get currentSong(): SongItem | null {
    return this.hasSong ? this.playlist[this.currentIndex] : null
  }

  // 销毁
  destroy(): void {
    this.stopTimer()
    if (this.avPlayer) {
      this.avPlayer.release()
    }
    this.listeners = []
  }
}

// 全局单例
export const player = new AudioPlayerState()
