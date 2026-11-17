import router from '@ohos.router'
import { player } from '../common/AudioPlayerUtil'

@Entry
@Component
struct MusicFlow {
  @State targetDevice: string = ''
  @State isFlowing: boolean = false
  @State flowProgress: number = 0

  private devices: string[] = ['MatePad Pro (平板)', '智慧屏 (电视)', 'MateBook X Pro (电脑)']

  build() {
    Column({ space: 0 }) {
      Row() {
        Text('‹').fontSize(60).fontColor('#FFFFFF').onClick(() => { router.back() })
        Blank()
        Text('音乐流转').fontSize(50).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
        Blank()
        Text('').width(32)
      }
      .width('100%').height(112).padding({ left: 34, right: 34 })

      Column({ space: 10 }) {
        Text('本机正在播放').fontSize(38).fontColor('#888888')
        Text(player.currentSong ? player.currentSong.name : '未播放')
          .fontSize(52).fontColor('#E8C575').fontWeight(FontWeight.Bold)
        Text(player.currentSong ? player.currentSong.artist : '')
          .fontSize(42).fontColor('#CCCCCC')
      }
      .width('100%').padding({ top: 36, bottom: 36 }).alignItems(HorizontalAlign.Center)

      Text('流转到以下设备').fontSize(42).fontColor('#888888')
        .width('100%').padding({ left: 22, top: 16, bottom: 14 })

      Column({ space: 0 }) {
        ForEach(this.devices, (dev: string) => {
          Row({ space: 18 }) {
            Row() {
              Text('📺').fontSize(56)
            }
            .width(96).height(96).borderRadius(22).backgroundColor('#353550')
            .justifyContent(FlexAlign.Center)

            Column({ space: 4 }) {
              Text(dev).fontSize(48).fontColor('#E8E8E8')
              Text(this.targetDevice === dev && this.isFlowing ? '流转中...' : '点击流转音乐')
                .fontSize(34).fontColor(this.targetDevice === dev ? '#E8C575' : '#888888')
            }
            .alignItems(HorizontalAlign.Start).layoutWeight(1)

            if (this.targetDevice === dev && this.isFlowing) {
              Text(`${this.flowProgress}%`).fontSize(42).fontColor('#E8C575')
            }
          }
          .width('100%').height(140).padding({ left: 34, right: 34 })
          .border({ width: { bottom: 0.5 }, color: '#2A2A40' })
          .onClick(() => {
            this.targetDevice = dev; this.isFlowing = true; this.flowProgress = 0
            const timer = setInterval(() => {
              this.flowProgress += 20
              if (this.flowProgress >= 100) {
                this.flowProgress = 100; clearInterval(timer)
                setTimeout(() => { this.isFlowing = false; this.flowProgress = 0 }, 500)
              }
            }, 300)
          })
        })
      }.width('100%')

      if (this.isFlowing) {
        Button('停止流转').width('75%').height(104).fontSize(46).fontColor('#FF6B6B')
          .backgroundColor(Color.Transparent).border({ width: 1, color: '#FF6B6B' })
          .borderRadius(34).margin({ top: 28 })
          .onClick(() => { this.isFlowing = false; this.targetDevice = ''; this.flowProgress = 0 })
      }

      Text('流转功能基于 HarmonyOS 分布式软总线，实现音乐在不同设备间无缝切换')
        .fontSize(34).fontColor('#666666').padding(40).textAlign(TextAlign.Center).width('100%')

      Blank()
    }
    .width('100%').height('100%').backgroundColor('#1A1A2E')
  }
}
