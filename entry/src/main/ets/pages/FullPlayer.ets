import router from '@ohos.router'
import mediaquery from '@ohos.mediaquery'
import display from '@ohos.display'
import { player, PlayMode, SongItem } from '../common/AudioPlayerUtil'
import { PlaylistDrawer } from '../common/PlaylistDrawer'

@Entry
@Component
struct FullPlayer {
  @StorageLink('theme') currentTheme: string = 'dark'
  @State currentTime: number = 0
  @State duration: number = 0
  @State isPlaying: boolean = false
  @State playMode: PlayMode = PlayMode.ListLoop
  @State songName: string = ''
  @State songArtist: string = ''
  @State songCover: ResourceStr = ''
  @State isLandscape: boolean = false
  @State showPlaylistDrawer: boolean = false
  @State drawerSongs: SongItem[] = []
  @State isFavorited: boolean = false
  // 进度条
  @State sliderValue: number = 0
  @State isDragging: boolean = false
  private seekLocked: boolean = false
  // 封面旋转
  @State spinAngle: number = 0
  private spinTimer?: number

  private isDark(): boolean { return this.currentTheme !== 'light' }
  private bgColor(): string { return this.isDark() ? '#1A1A2E' : '#FFFFFF' }
  private textPrimary(): string { return this.isDark() ? '#FFFFFF' : '#111111' }
  private textSecondary(): string { return this.isDark() ? '#888888' : '#999999' }
  private textHint(): string { return this.isDark() ? '#CCCCCC' : '#666666' }

  private startSpin(): void {
    if (this.spinTimer !== undefined) return
    this.spinTimer = setInterval(() => { this.spinAngle = (this.spinAngle + 2) % 360 }, 30)
  }
  private stopSpin(): void {
    if (this.spinTimer !== undefined) { clearInterval(this.spinTimer); this.spinTimer = undefined }
  }

  private mediaQueryListener?: mediaquery.MediaQueryListener
  private refreshCb: () => void = () => {
    this.currentTime = Number.isFinite(player.currentTime) ? Math.max(0, player.currentTime) : 0
    this.duration = Number.isFinite(player.duration) ? Math.max(0, player.duration) : 0
    this.isPlaying = player.isPlaying
    this.playMode = player.playMode
    const song = player.currentSong
    if (song) {
      if (this.songName !== song.name) {
        this.spinAngle = 0 // 切歌时重置封面角度
      }
      this.songName = song.name
      this.songArtist = song.artist
      this.songCover = song.cover ?? ''
    } else {
      this.songCover = ''
    }
    this.drawerSongs = [...player.playlist]
    this.isFavorited = player.isCurrentFavorite
    if (!this.isDragging && !this.seekLocked && this.duration > 0) {
      this.sliderValue = this.currentTime / this.duration * 100
    }
    // 封面旋转
    if (this.isPlaying && this.spinTimer === undefined) { this.startSpin() }
    if (!this.isPlaying && this.spinTimer !== undefined) { this.stopSpin() }
  }

  aboutToAppear(): void {
    player.subscribe(this.refreshCb)
    this.refreshCb()


    // 横竖屏检测
    try {
      const listener = mediaquery.matchMediaSync('(orientation: landscape)')
      this.isLandscape = listener.matches
      listener.on('change', (result: mediaquery.MediaQueryResult) => {
        this.isLandscape = result.matches
      })
      this.mediaQueryListener = listener
    } catch (e) {
      this.isLandscape = false
    }
  }

  aboutToDisappear(): void {
    this.stopSpin()
    player.unsubscribe(this.refreshCb)
    try {
      if (this.mediaQueryListener) {
        this.mediaQueryListener.off('change')
      }
    } catch (e) {
    }
  }

  // ==================== 封面区（含唱片指针） ====================
  @Builder
  AlbumArt(size: number) {
    Stack() {
      // 旋转唱片封面
      Row() {
        if (this.songCover) {
          Image(this.songCover)
            .width(size).height(size)
            .borderRadius(size / 2)
            .rotate({ angle: this.spinAngle })
            .objectFit(ImageFit.Cover)
        } else {
          Image($rawfile('music.png'))
            .width(size * 0.67).height(size * 0.67)
            .rotate({ angle: this.spinAngle })
            .objectFit(ImageFit.Contain)
        }
      }
      .width(size).height(size)
      .borderRadius(size / 2)
      .backgroundColor('#353550').justifyContent(FlexAlign.Center)

      // 唱片指针（右上角，播放时搭上唱片，暂停时抬起）
      Image($rawfile('唱片指针.png'))
        .width(size * 0.22)
        .objectFit(ImageFit.Contain)
        .rotate({
          angle: this.isPlaying ? 0 : -20,
          centerX: '50%',
          centerY: 0
        })
        .animation({
          duration: 400,
          curve: Curve.EaseInOut
        })
        .position({
          x: size * 0.72,
          y: -size * 0.08
        })
    }
    .width(size * 1.1).height(size * 1.1)
    .alignContent(Alignment.Center)
  }

  // ==================== 歌曲信息 ====================
  @Builder
  SongInfo() {
    Column({ space: 18 }) {
      Row({ space: 24 }) {
        Text(this.songName || '未选择歌曲')
          .fontSize(this.isLandscape ? 44 : 56)
          .fontColor(this.textPrimary()).fontWeight(FontWeight.Bold).maxLines(1).layoutWeight(1)
        Image(this.isFavorited ? $rawfile('heart_fill.png') : $rawfile('heart.png'))
          .width(this.isLandscape ? 48 : 56).height(this.isLandscape ? 48 : 56).objectFit(ImageFit.Contain)
          .onClick(() => { player.toggleCurrentFavorite() })
      }
      .width('100%')

      Text(this.songArtist || '')
        .fontSize(this.isLandscape ? 34 : 42).fontColor(this.textSecondary()).width('100%')
    }
    .width('100%')
  }

  // ==================== 进度条（Slider） ====================
  @Builder
  ProgressBar() {
    Column({ space: 18 }) {
      Slider({
        value: this.sliderValue,
        min: 0,
        max: 100,
        step: 1,
        style: SliderStyle.OutSet
      })
        .width('100%')
        .blockColor('#E8C575')
        .trackColor('#353550')
        .selectedColor('#E8C575')
        .onChange((value: number, mode: SliderChangeMode) => {
          if (this.duration <= 0) { return }
          if (mode === SliderChangeMode.Begin || mode === SliderChangeMode.Moving) {
            this.isDragging = true
          }
          this.sliderValue = value
          if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
            const seekSec = value / 100 * this.duration
            player.seekTo(Math.floor(seekSec))
            this.isDragging = false
            this.seekLocked = true
            setTimeout(() => { this.seekLocked = false }, 800)
            if (!this.isPlaying) { player.togglePlay() }
          }
        })

      // 时间
      Row() {
        Text(player.formatTime(Math.floor(this.sliderValue / 100 * (this.duration || 0)))).fontSize(32).fontColor('#888888')
        Blank()
        Text(player.formatTime(this.duration || 0)).fontSize(32).fontColor('#888888')
      }.width('100%')
    }
    .width('100%')
  } 

  // ==================== 控制按钮 ====================
  @Builder
  Controls() {
    Row({ space: 18 }) {
      Image(this.playMode === PlayMode.Shuffle ? $rawfile('shuffle.png') :
        this.playMode === PlayMode.SingleLoop ? $rawfile('repeat_1.png') : $rawfile('repeat.png'))
        .width(58).height(58).objectFit(ImageFit.Contain).onClick(() => { player.cycleMode() })

      Blank()

      Image($rawfile('backward_end_fill.png')).width(76).height(76).objectFit(ImageFit.Contain).onClick(() => { player.prev() })

      Row() {
        Image(this.isPlaying ? $rawfile('pause_round_triangle_fill.png') : $rawfile('play_circle_fill.png'))
          .width(82).height(82).objectFit(ImageFit.Contain)
      }
     // .width(100).height(100).borderRadius(50).backgroundColor('#E8C575')
      .justifyContent(FlexAlign.Center).onClick(() => { player.togglePlay() })

      Image($rawfile('forward_end_fill.png')).width(76).height(76).objectFit(ImageFit.Contain).onClick(() => { player.next() })

      Blank()

      Image($rawfile('music_note_list.png')).width(58).height(58).objectFit(ImageFit.Contain)
        .onClick(() => { this.showPlaylistDrawer = !this.showPlaylistDrawer })
    }
    .width('100%').padding({ left: 48, right: 48, bottom: 64 })
  }

  // ==================== 横屏布局 ====================
  @Builder
  LandscapeLayout() {
    Column() {
      this.TopBar()

      Column() {
        this.AlbumArt(800)
      }
      .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)

      Column({ space: 28 }) {
        this.SongInfo()
        this.ProgressBar()
        this.Controls()
      }
      .width('100%').padding({ left: 36, right: 36, bottom: 42 })
    }
    .width('100%').height('100%').backgroundColor(this.bgColor())
  }

  // ==================== 横屏布局（左右分栏） ====================
  @Builder
  PortraitLayout() {
    Column() {
      this.TopBar()

      Row({ space: 32 }) {
        // 左侧封面：以屏幕高度为基准自适应
        Column() {
          this.AlbumArt(800)
        }
        .layoutWeight(1).justifyContent(FlexAlign.Center)

        // 右侧信息 + 控制
        Column({ space: 20 }) {
          this.SongInfo()
          this.ProgressBar()
          this.Controls()
        }
        .layoutWeight(1).justifyContent(FlexAlign.Center)
        .padding({ right: 36 })
      }
      .layoutWeight(1).width('100%').padding({ left: 36, bottom: 24 })
    }
    .width('100%').height('100%').backgroundColor(this.bgColor())
  }

  // ==================== 顶栏 ====================
  @Builder
  TopBar() {
    Row() {
      Image($rawfile('chevron_down.png')).width(58).height(58).objectFit(ImageFit.Contain).onClick(() => { router.back() })
      Blank()
      Text('正在播放').fontSize(46).fontColor(this.textSecondary())
      Blank()
      Text('⋯').fontSize(52).fontColor(this.textHint())
    }
    .width('100%').height(112).padding({ left: 36, right: 36 })
  }

  build() {
    Stack() {
      if (this.isLandscape) {
        this.LandscapeLayout()
      } else {
        this.PortraitLayout()
      }

      PlaylistDrawer({
        show: this.showPlaylistDrawer,
        songs: this.drawerSongs,
        currentSongName: this.songName,
        onClose: () => { this.showPlaylistDrawer = false }
      })
    }
  }
}
