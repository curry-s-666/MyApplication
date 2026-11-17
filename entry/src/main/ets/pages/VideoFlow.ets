import router from '@ohos.router'

@Entry
@Component
struct VideoFlow {
  @State targetDevice: string = ''
  @State isFlowing: boolean = false
  @State isPlaying: boolean = false

  private devices: string[] = ['智慧屏 (客厅)', 'MatePad Pro', 'MateBook X Pro']

  build() {
    Column({ space: 0 }) {
      Row() {
        Text('‹').fontSize(60).fontColor('#FFFFFF').onClick(() => { router.back() })
        Blank()
        Text('视频流转').fontSize(50).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
        Blank()
        Text('').width(32)
      }
      .width('100%').height(112).padding({ left: 34, right: 34 })

      Stack() {
        Column() {
          Text('🎬').fontSize(96).fontColor('#CCCCCC')
          Text('MV 演示视频').fontSize(48).fontColor('#888888').margin({ top: 18 })
          if (this.isFlowing && this.targetDevice !== '') {
            Text(`正在流转到 ${this.targetDevice}`).fontSize(38).fontColor('#E8C575').margin({ top: 18 })
          }
        }
        .width('100%').aspectRatio(16 / 9).backgroundColor('#0A0A18')
        .justifyContent(FlexAlign.Center)

        Row() {
          Text(this.isPlaying ? '⏸' : '▶').fontSize(68).fontColor('#E8C575')
        }
        .align(Alignment.Center).onClick(() => { this.isPlaying = !this.isPlaying })
      }.width('100%')

      Text('选择流转设备').fontSize(42).fontColor('#888888')
        .width('100%').padding({ left: 22, top: 24, bottom: 14 })

      Column({ space: 0 }) {
        ForEach(this.devices, (dev: string) => {
          Row({ space: 18 }) {
            Row() {
              Text(dev.includes('智慧屏') ? '📺' : dev.includes('Pad') ? '📋' : '💻').fontSize(56)
            }
            .width(96).height(96).borderRadius(22).backgroundColor('#353550')
            .justifyContent(FlexAlign.Center)

            Text(dev).fontSize(48).fontColor('#E8E8E8').layoutWeight(1)

            if (this.targetDevice === dev && this.isFlowing) {
              Text('✓ 流转中').fontSize(38).fontColor('#E8C575')
            } else {
              Text('流转 >').fontSize(38).fontColor('#555555')
            }
          }
          .width('100%').height(140).padding({ left: 34, right: 34 })
          .border({ width: { bottom: 0.5 }, color: '#2A2A40' })
          .onClick(() => {
            this.targetDevice = dev; this.isFlowing = true
            setTimeout(() => { this.isFlowing = false }, 2000)
          })
        })
      }.width('100%')

      Column({ space: 12 }) {
        Text('跨设备应用联动').fontSize(42).fontColor('#E8E8E8')
        Text('视频播放与音乐播放使用不同解码器，流转时需要处理视频帧同步、音频轨道映射等关键流程')
          .fontSize(34).fontColor('#666666').textAlign(TextAlign.Center)
      }.width('100%').padding(30)

      Blank()
    }
    .width('100%').height('100%').backgroundColor('#1A1A2E')
  }
}
