import router from '@ohos.router'
import { player, SongItem } from '../common/AudioPlayerUtil'
import { PlaylistDrawer } from '../common/PlaylistDrawer'
import media from '@ohos.multimedia.media'

@Entry
@Component
struct PlaylistDetail {
  @StorageLink('theme') currentTheme: string = 'dark'
  @State headerCollapsed: boolean = false
  // 播放列表抽屉
  @State showPlaylistDrawer: boolean = false
  @State drawerSongs: SongItem[] = []
  // 迷你播放器状态
  @State miniSongName: string = ''
  @State miniArtist: string = ''
  @State miniPlaying: boolean = false
  @State miniCover: ResourceStr = ''
  @State isFavorited: boolean = false
  @State favoritedNames: string[] = []
  @State playButtonSticky: boolean = false
  // 滚动控制器
  private scroller: Scroller = new Scroller()
  // 歌单数据
  private songCatalog: SongItem[] = [
    {
      name: '半岛铁盒',
      artist: '周杰伦',
      duration: 302,
      cover: $rawfile('ZJL.PNG'),
      rawfile: '周杰伦 - 半岛铁盒.mp3'
    },
    {
      name: '安静',
      artist: '周杰伦',
      duration: 330,
      cover: $rawfile('ZJL.PNG'),
      rawfile: '周杰伦 - 安静.mp3'
    },
    {
      name: '斗牛',
      artist: '周杰伦',
      duration: 257,
      cover: $rawfile('ZJL.PNG'),
      rawfile: '周杰伦 - 斗牛.mp3'
    },
    {
      name: '爱在西元前',
      artist: '周杰伦',
      duration: 238,
      cover: $rawfile('ZJL.PNG'),
      rawfile: '周杰伦 - 爱在西元前.mp3'
    },
    {
      name: '稻香',
      artist: '周杰伦',
      duration: 223,
      cover: $rawfile('ZJL.PNG'),
      rawfile: '周杰伦 - 稻香.mp3'
    },
    {
      name: '等你下课',
      artist: '周杰伦',
      duration: 272,
      cover: $rawfile('ZJL.PNG'),
      rawfile: '周杰伦 - 等你下课.mp3'
    },
    {
      name: '简单爱',
      artist: '周杰伦',
      duration: 269,
      cover: $rawfile('ZJL.PNG'),
      rawfile: 'mp3.mp3'
    },
    {
      name: '遥远的她',
      artist: '张学友',
      duration: 290,
      cover: $rawfile('张学友 - 遥远的她.png'),
      rawfile: '张学友 - 遥远的她.mp3'
    },
    {
      name: '落了白',
      artist: '蒋雪儿',
      duration: 248,
      cover: $rawfile('蒋雪儿Snow.J - 落了白.png'),
      rawfile: '蒋雪儿Snow.J - 落了白.mp3'
    },
    {
      name: '转身即心痛',
      artist: '谭维维,黄子弘凡',
      duration: 225,
      cover: $rawfile('谭维维,黄子弘凡 - 转身即心痛.png'),
      rawfile: '谭维维,黄子弘凡 - 转身即心痛 (Live版).mp3'
    },
    {
      name: '罗生门',
      artist: '张子豪',
      duration: 225,
      cover: $rawfile('罗生门.png'),
      url: 'http://music.163.com/song/media/outer/url?id=1456890009.mp3'
    },
    {
      name: '苦茶子',
      artist: 'Starling8,DRODUMANA,FIVESTAR',
      duration: 225,
      cover: $rawfile('苦茶子.png'),
      url: 'http://music.163.com/song/media/outer/url?id=1922888354.mp3'
    },
  ]
  private playlistName: string = '我的歌单'
  private playlistDesc: string = '共12首'
  @State playlistNameState: string = '我的歌单'
  @State playlistDescState: string = '共12首'
  @State playlistCover: ResourceStr = $rawfile('music.png')

  private isDark(): boolean {
    return this.currentTheme !== 'light'
  }

  private bgColor(): string {
    return this.isDark() ? '#1A1A2E' : '#FFFFFF'
  }

  private textPrimary(): string {
    return this.isDark() ? '#E8E8E8' : '#111111'
  }

  private textSecondary(): string {
    return this.isDark() ? '#888888' : '#999999'
  }

  private textHint(): string {
    return this.isDark() ? '#666666' : '#AAAAAA'
  }

  private surfaceColor(): string {
    return this.isDark() ? '#252540' : '#F2F3F5'
  }

  private accentColor(): string {
    return '#E8C575'
  }

  private dividerColor(): string {
    return this.isDark() ? '#2A2A40' : '#E6E6E6'
  }

  // 迷你播放器 & 抽屉刷新回调
  private refreshMini = (): void => {
    const s = player.currentSong
    this.miniSongName = s ? s.name : ''
    this.miniArtist = s ? s.artist : ''
    this.miniPlaying = player.isPlaying
    this.miniCover = (s && s.cover) ? s.cover : $rawfile('music.png')
    this.isFavorited = player.isCurrentFavorite
    // 同步播放列表到抽屉
    this.drawerSongs = [...player.playlist]
  }

  aboutToAppear(): void {
    player.initContext(getContext(this))
    this.refreshMini()
    this.favoritedNames = Array.from(player.favorites)
    player.subscribe(this.refreshMini)
    // 读取路由参数
    const params = router.getParams() as Record<string, Object> | undefined
    if (params) {
      if (params['name']) this.playlistNameState = params['name'] as string
      if (params['desc']) this.playlistDescState = params['desc'] as string
      if (params['cover']) this.playlistCover = params['cover'] as ResourceStr
    }
  }

  aboutToDisappear(): void {
    player.unsubscribe(this.refreshMini)
  }

  // 点歌即加入播放列表并立即播放
  private playSongNow(song: SongItem): void {
    player.addSong(song, true)
  }

  // 添加一首歌不中断播放
  private addSongQuiet(song: SongItem): void {
    player.addSong(song, false)
  }

  build() {
    Stack() {
      Column({ space: 0 }) {
        // ===== 顶栏 =====
        Row() {
          Row() {
            Text('back').fontSize(46).fontColor('#E8C575')
          }.width(104).height(88).justifyContent(FlexAlign.Center).onClick(() => {
            router.back()
          })

          Text(this.playlistNameState)
            .fontSize(42)
            .fontColor(this.textPrimary())
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
            .padding({ left: 8 })
            .opacity(this.headerCollapsed ? 1 : 0)

          Row({ space: 28 }) {
            Image($rawfile('搜索.png')).width(52).height(52).objectFit(ImageFit.Contain)
            Text('•••').fontSize(46).fontColor(this.textPrimary()).letterSpacing(3)
          }.height(88).padding({ right: 12 })
        }
        .width('100%').height(110).padding({ left: 18, right: 18 })
        .backgroundColor(this.bgColor())
        .zIndex(10)



        // ===== 内容区 =====
        Stack() {
          // 歌单列表
          Scroll(this.scroller) {

            Column({ space: 0 }) {
              // 封面区（滚动收起）

              Column({ space: 22 }) {
                Column() {
                  Image(this.playlistCover)
                    .width(360).height(360).objectFit(ImageFit.Cover).borderRadius(32)
                }
                .width(360)
                .height(360)
                .borderRadius(32)
                .backgroundColor(this.surfaceColor())
                .justifyContent(FlexAlign.Center)
                .clip(true)

                Text(this.playlistNameState)
                  .fontSize(56).fontColor(this.textPrimary()).fontWeight(FontWeight.Bold)
                Text(this.playlistDescState)
                  .fontSize(38).fontColor(this.textSecondary())
              }
              .width('100%').alignItems(HorizontalAlign.Center)
              .padding({ top: 24, bottom: 24 })

              // 操作按钮区
              Row({ space: 20 }) {
                Button('播放全部')
                  .fontSize(38)
                  .fontColor('#333333')
                  .backgroundColor('#E8C575')
                  .borderRadius(44)
                  .height(88)
                  .width(280)
                  .onClick(() => {
                    player.replaceAndPlayAll(this.songCatalog)
                  })
              }
              .width('100%').padding({ left: 36, right: 36, top: 12, bottom: 12 })
              .backgroundColor(this.bgColor()).height(150)
              .opacity(this.playButtonSticky ? 0 : 1)

              List() {
                // 歌曲列表
                ForEach(this.songCatalog, (song: SongItem, index: number) => {
                  ListItem() {
                    Row({ space: 18 }) {
                      Text(`${index + 1}`)
                        .fontSize(40)
                        .fontColor(this.textHint())
                        .width(64)
                        .textAlign(TextAlign.Center)
                        .onClick(() => {
                          this.playSongNow(song)
                        })

                      Column({ space: 8 }) {
                        Text(song.name)
                          .fontSize(50).fontColor(this.textPrimary()).fontWeight(FontWeight.Medium).maxLines(1)
                        Text(song.artist)
                          .fontSize(36).fontColor(this.textSecondary()).maxLines(1)
                      }
                      .alignItems(HorizontalAlign.Start).layoutWeight(1)
                      .onClick(() => {
                        this.playSongNow(song)
                      })

                      Image(this.favoritedNames.includes(song.name) ? $rawfile('heart_fill.png') : $rawfile('heart.png'))
                        .width(44).height(44).objectFit(ImageFit.Contain)
                        .onClick(() => {
                          player.toggleFavorite(song)
                          this.favoritedNames = Array.from(player.favorites)
                        })

                      Image($rawfile('play_fill.png'))
                        .width(50).height(50).objectFit(ImageFit.Contain)
                        .onClick(() => {
                          this.playSongNow(song)
                        })

                      // 添加按钮（不中断播放）
                      Row() {
                        Text('+')
                          .fontSize(46).fontColor(this.accentColor()).fontWeight(FontWeight.Bold)
                      }
                      .width(66).height(66).justifyContent(FlexAlign.Center)
                      .onClick(() => {
                        this.addSongQuiet(song)
                      })
                    }
                    .width('100%').height(132).padding({ left: 34, right: 34 })
                  }
                }, (song: SongItem) => song.name)
              }
              .width('100%').scrollBar(BarState.Off).height(1540)
              .nestedScroll({scrollForward:NestedScrollMode.PARENT_FIRST,
                scrollBackward:NestedScrollMode.SELF_FIRST})
            }

          }
          .scrollBar(BarState.Off)
          .onScroll(() => {
            const offsetY = this.scroller.currentOffset().yOffset
            if (offsetY > 550 && !this.headerCollapsed) {
              this.headerCollapsed = true
            } else if (offsetY <= 500 && this.headerCollapsed) {
              this.headerCollapsed = false
            }
            // 播放按钮悬停：封面区滚过时固定在顶栏下方
            if (offsetY > 550 && !this.playButtonSticky) {
              this.playButtonSticky = true
            } else if (offsetY <= 530 && this.playButtonSticky) {
              this.playButtonSticky = false
            }
          })

          // 悬停播放全部按钮
          if (this.playButtonSticky) {
            Row({ space: 20 }) {
              Button('播放全部')
                .fontSize(38)
                .fontColor('#333333')
                .backgroundColor('#E8C575')
                .borderRadius(44)
                .height(88)
                .width(280)
                .onClick(() => {
                  player.replaceAndPlayAll(this.songCatalog)
                })
            }
            .width('100%').height(120)
            .padding({ left: 36, right: 36, top: 12, bottom: 12 })
            .backgroundColor(this.bgColor())
            .alignItems(VerticalAlign.Bottom)
            .shadow({ radius: 8, color: '#00000030', offsetY: 2 })
            .position({ x: 0, y: 0 })
            .zIndex(5)
          }


          // ===== 播放列表抽屉（共享组件） =====
          PlaylistDrawer({
            show: this.showPlaylistDrawer,
            songs: this.drawerSongs,
            currentSongName: this.miniSongName,
            onClose: () => {
              this.showPlaylistDrawer = false
            }
          })
        }
        .width('100%').layoutWeight(1).clip(true)

        // ===== 迷你播放器（始终在底部） =====
        Row({ space: 22 }) {
          Row() {
            Image(this.miniCover ? this.miniCover : $rawfile('music.png'))
              .width(88).height(88).borderRadius(16).objectFit(ImageFit.Cover)
          }
          .width(88)
          .height(88)
          .borderRadius(16)
          .backgroundColor(this.surfaceColor())
          .onClick(() => {
            router.pushUrl({ url: 'pages/FullPlayer' })
          })

          Column({ space: 6 }) {
            Text(this.miniSongName || '未播放歌曲')
              .fontSize(44).fontColor(this.textPrimary()).maxLines(1)
            Text(this.miniArtist || '')
              .fontSize(32).fontColor(this.textSecondary()).maxLines(1)
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)
          .onClick(() => {
            router.pushUrl({ url: 'pages/FullPlayer' })
          })

          Row({ space: 28 }) {
            // 爱心
            Image(this.isFavorited ? $rawfile('heart_fill.png') : $rawfile('heart.png'))
              .width(48).height(48).objectFit(ImageFit.Contain)
              .onClick(() => { player.toggleCurrentFavorite() })

            // 播放/暂停
            Row() {
              Image(this.miniPlaying ? $rawfile('pause_round_triangle_fill.png') : $rawfile('play_circle_fill.png'))
                .width(54).height(54).objectFit(ImageFit.Contain)
            }.width(80).height(80).justifyContent(FlexAlign.Center)
            .onClick(() => {
              if (player.hasSong) player.togglePlay()
            })

            // 下一曲
            Row() {
              Image($rawfile('forward_end_fill.png'))
                .width(48).height(48).objectFit(ImageFit.Contain)
            }.width(80).height(80).justifyContent(FlexAlign.Center)
            .onClick(() => {
              player.next()
            })

            // 播放列表（最右侧）
            Row() {
              Image($rawfile('music_note_list.png'))
                .width(48).height(48).objectFit(ImageFit.Contain)
            }.width(80).height(80).justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.showPlaylistDrawer = !this.showPlaylistDrawer
            })
          }
        }
        .width('100%').height(120).padding({ left: 30, right: 30 })
      }
      .width('100%').height('100%').backgroundColor(this.bgColor())
    }
  }
}
