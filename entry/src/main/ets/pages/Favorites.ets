import router from '@ohos.router'
import { player, SongItem } from '../common/AudioPlayerUtil'
import { PlaylistDrawer } from '../common/PlaylistDrawer'

@Entry
@Component
struct Favorites {
  @StorageLink('theme') currentTheme: string = 'dark'
  @State headerCollapsed: boolean = false
  @State showPlaylistDrawer: boolean = false
  @State drawerSongs: SongItem[] = []
  @State miniSongName: string = ''
  @State miniArtist: string = ''
  @State miniPlaying: boolean = false
  @State miniCover: ResourceStr = ''
  @State isFavorited: boolean = false
  @State favoriteSongs: SongItem[] = []
  private scroller: Scroller = new Scroller()
  private playlistName: string = '我的收藏'

  private isDark(): boolean { return this.currentTheme !== 'light' }
  private bgColor(): string { return this.isDark() ? '#1A1A2E' : '#FFFFFF' }
  private textPrimary(): string { return this.isDark() ? '#E8E8E8' : '#111111' }
  private textSecondary(): string { return this.isDark() ? '#888888' : '#999999' }
  private textHint(): string { return this.isDark() ? '#666666' : '#AAAAAA' }
  private surfaceColor(): string { return this.isDark() ? '#252540' : '#F2F3F5' }
  private accentColor(): string { return '#E8C575' }

  private refreshCb = (): void => {
    const s = player.currentSong
    this.miniSongName = s ? s.name : ''
    this.miniArtist = s ? s.artist : ''
    this.miniPlaying = player.isPlaying
    this.miniCover = (s && s.cover) ? s.cover : $rawfile('music.png')
    this.isFavorited = player.isCurrentFavorite
    this.drawerSongs = [...player.playlist]
    this.favoriteSongs = [...player.favoriteSongs]
  }

  aboutToAppear(): void {
    player.subscribe(this.refreshCb)
    this.refreshCb()
  }

  aboutToDisappear(): void {
    player.unsubscribe(this.refreshCb)
  }

  private playSongNow(song: SongItem): void {
    player.addSong(song, true)
  }

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

          Text(this.playlistName)
            .fontSize(42)
            .fontColor(this.textPrimary())
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
            .padding({ left: 8 })
            .opacity(this.headerCollapsed ? 1 : 0)

          Row({ space: 28 }) {
            Text('•••').fontSize(46).fontColor(this.textPrimary()).letterSpacing(3)
          }.height(88).padding({ right: 12 })
        }
        .width('100%').height(110).padding({ left: 18, right: 18 })
        .backgroundColor(this.bgColor())
        .zIndex(10)

        // ===== 内容区 =====
        Stack() {
          Scroll(this.scroller) {
            Column({ space: 0 }) {
              // 封面区
              Column({ space: 22 }) {
                Column() {
                  Image($rawfile('heart_fill.png'))
                    .width(120).height(120).objectFit(ImageFit.Contain)
                }
                .width(360)
                .height(360)
                .borderRadius(32)
                .backgroundColor(this.surfaceColor())
                .justifyContent(FlexAlign.Center)

                Text(this.playlistName)
                  .fontSize(56).fontColor(this.textPrimary()).fontWeight(FontWeight.Bold)
                Text(`共${this.favoriteSongs.length}首`)
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
                    player.replaceAndPlayAll(this.favoriteSongs)
                  })
              }
              .width('100%').padding({ left: 36, right: 36, top: 12, bottom: 12 })
              .backgroundColor(this.bgColor()).height(150)

              // 歌曲列表
              List() {
                ForEach(this.favoriteSongs, (song: SongItem, index: number) => {
                  ListItem() {
                    Row({ space: 18 }) {
                      Text(`${index + 1}`)
                        .fontSize(40)
                        .fontColor(this.textHint())
                        .width(64)
                        .textAlign(TextAlign.Center)
                        .onClick(() => { this.playSongNow(song) })

                      Column({ space: 8 }) {
                        Text(song.name)
                          .fontSize(50).fontColor(this.textPrimary()).fontWeight(FontWeight.Medium).maxLines(1)
                        Text(song.artist)
                          .fontSize(36).fontColor(this.textSecondary()).maxLines(1)
                      }
                      .alignItems(HorizontalAlign.Start).layoutWeight(1)
                      .onClick(() => { this.playSongNow(song) })

                      Image($rawfile('heart_fill.png'))
                        .width(44).height(44).objectFit(ImageFit.Contain)
                        .onClick(() => { player.toggleFavorite(song) })

                      Image($rawfile('play_fill.png'))
                        .width(50).height(50).objectFit(ImageFit.Contain)
                        .onClick(() => { this.playSongNow(song) })

                      Row() {
                        Text('+')
                          .fontSize(46).fontColor(this.accentColor()).fontWeight(FontWeight.Bold)
                      }
                      .width(66).height(66).justifyContent(FlexAlign.Center)
                      .onClick(() => { this.addSongQuiet(song) })
                    }
                    .width('100%').height(132).padding({ left: 34, right: 34 })
                  }
                }, (song: SongItem) => song.name)
              }
              .width('100%').scrollBar(BarState.Off).height(1540)
              .nestedScroll({ scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.SELF_FIRST })
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
          })

          PlaylistDrawer({
            show: this.showPlaylistDrawer,
            songs: this.drawerSongs,
            currentSongName: this.miniSongName,
            onClose: () => { this.showPlaylistDrawer = false }
          })
        }
        .width('100%').layoutWeight(1).clip(true)

        // ===== 迷你播放器 =====
        Row({ space: 22 }) {
          Row() {
            Image(this.miniCover ? this.miniCover : $rawfile('music.png'))
              .width(88).height(88).borderRadius(16).objectFit(ImageFit.Cover)
          }
          .width(88).height(88).borderRadius(16)
          .backgroundColor(this.surfaceColor())
          .onClick(() => { router.pushUrl({ url: 'pages/FullPlayer' }) })

          Column({ space: 6 }) {
            Text(this.miniSongName || '未播放歌曲')
              .fontSize(44).fontColor(this.textPrimary()).maxLines(1)
            Text(this.miniArtist || '')
              .fontSize(32).fontColor(this.textSecondary()).maxLines(1)
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)
          .onClick(() => { router.pushUrl({ url: 'pages/FullPlayer' }) })

          Row({ space: 28 }) {
            Image(this.isFavorited ? $rawfile('heart_fill.png') : $rawfile('heart.png'))
              .width(48).height(48).objectFit(ImageFit.Contain)
              .onClick(() => { player.toggleCurrentFavorite() })

            Row() {
              Image(this.miniPlaying ? $rawfile('pause_round_triangle_fill.png') : $rawfile('play_circle_fill.png'))
                .width(54).height(54).objectFit(ImageFit.Contain)
            }.width(80).height(80).justifyContent(FlexAlign.Center)
            .onClick(() => { if (player.hasSong) player.togglePlay() })

            Row() {
              Image($rawfile('forward_end_fill.png'))
                .width(48).height(48).objectFit(ImageFit.Contain)
            }.width(80).height(80).justifyContent(FlexAlign.Center)
            .onClick(() => { player.next() })

            Row() {
              Image($rawfile('music_note_list.png'))
                .width(48).height(48).objectFit(ImageFit.Contain)
            }.width(80).height(80).justifyContent(FlexAlign.Center)
            .onClick(() => { this.showPlaylistDrawer = !this.showPlaylistDrawer })
          }
        }
        .width('100%').height(120).padding({ left: 30, right: 30 })
      }
      .width('100%').height('100%').backgroundColor(this.bgColor())
    }
  }
}
