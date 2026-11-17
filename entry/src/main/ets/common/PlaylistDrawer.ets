import { player, SongItem } from './AudioPlayerUtil'

@Component
export struct PlaylistDrawer {
  @StorageLink('theme') currentTheme: string = 'dark'
  @Prop show: boolean = false
  @Prop songs: SongItem[] = []
  @Prop currentSongName: string = ''
  onClose?: () => void

  private isDark(): boolean { return this.currentTheme !== 'light' }
  private textPrimary(): string { return this.isDark() ? '#E8E8E8' : '#111111' }
  private textSecondary(): string { return this.isDark() ? '#888888' : '#999999' }
  private textHint(): string { return this.isDark() ? '#666666' : '#AAAAAA' }
  private bgColor(): string { return this.isDark() ? '#1E1E3A' : '#FFFFFF' }
  private dividerColor(): string { return this.isDark() ? '#2A2A40' : '#E6E6E6' }
  private accentColor(): string { return '#E8C575' }

  build() {
    if (this.show) {
      Column() {
        // 上方空白遮罩：点击回到原界面
        Column() {}.width('100%').layoutWeight(1).backgroundColor('#66000000')
          .onClick(() => { this.onClose?.() })

        // 抽屉本体
        Column() {
          // 标题栏
          Row() {
            Text('播放列表')
              .fontSize(48).fontColor(this.textPrimary()).fontWeight(FontWeight.Bold)
            Blank()
            Text('全部删除')
              .fontSize(36).fontColor('#FF6B6B')
              .onClick(() => { player.clearPlaylist() })
            Text('收起')
              .fontSize(36).fontColor(this.accentColor())
              .margin({ left: 32 })
              .onClick(() => { this.onClose?.() })
          }
          .width('100%').height(112).padding({ left: 34, right: 34 })

          Row() {}.width('100%').height(2).backgroundColor(this.dividerColor())

          // 内容
          if (this.songs.length === 0) {
            Column() {
              Text('播放列表为空')
                .fontSize(40).fontColor(this.textHint())
              Text('点击歌单中的歌曲或「+」添加')
                .fontSize(32).fontColor(this.textHint()).margin({ top: 8 })
            }
            .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
          } else {
            List({ space: 0 }) {
              ForEach(this.songs, (song: SongItem, idx: number) => {
                ListItem() {
                  Row({ space: 16 }) {
                    Text(idx === player.currentIndex && player.isPlaying ? '♪' : `${idx + 1}`)
                      .fontSize(34)
                      .fontColor(idx === player.currentIndex ? this.accentColor() : this.textHint())
                      .width(56).textAlign(TextAlign.Center)
                      .onClick(() => { player.playAtIndex(idx) })

                    Column({ space: 4 }) {
                      Text(song.name)
                        .fontSize(42)
                        .fontColor(idx === player.currentIndex ? this.accentColor() : this.textPrimary())
                        .maxLines(1)
                      Text(song.artist)
                        .fontSize(30).fontColor(this.textSecondary()).maxLines(1)
                    }
                    .alignItems(HorizontalAlign.Start).layoutWeight(1)
                    .onClick(() => { player.playAtIndex(idx) })

                    Row() {
                      Text('删除').fontSize(34).fontColor('#FF6B6B')
                    }
                      .width(110).height(72).justifyContent(FlexAlign.Center)
                      .onClick(() => { player.removeSong(idx) })
                  }
                  .width('100%').height(112).padding({ left: 34, right: 24 })
                }
              }, (song: SongItem, idx: number) => `${song.name}_${idx}_${this.currentSongName}`)
            }
            .width('100%').layoutWeight(1).scrollBar(BarState.Off)
          }
        }
        .width('100%').height('55%')
        .backgroundColor(this.bgColor())
        .borderRadius({ topLeft: 28, topRight: 28 })
        .shadow({ radius: 20, color: '#00000060', offsetY: -4 })
      }
      .width('100%').height('100%').zIndex(100)
      .transition(TransitionEffect.translate({ y: 700 }).animation({ duration: 260, curve: Curve.EaseOut }))
    }
  }
}
