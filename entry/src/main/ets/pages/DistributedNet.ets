import router from '@ohos.router'

interface DeviceInfo {
  name: string
  type: string
  online: boolean
}

@Entry
@Component
struct DistributedNet {
  @State devices: DeviceInfo[] = [
    { name: 'Mate 60 Pro', type: '手机', online: true },
    { name: 'MatePad Pro', type: '平板', online: true },
    { name: 'MateBook X Pro', type: '电脑', online: false },
  ]
  @State isNetworking: boolean = false

  build() {
    Column({ space: 0 }) {
      Row() {
        Text('‹').fontSize(60).fontColor('#FFFFFF').onClick(() => { router.back() })
        Blank()
        Text('分布式组网').fontSize(50).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
        Blank()
        Text('').width(32)
      }
      .width('100%').height(112).padding({ left: 34, right: 34 })

      Row({ space: 14 }) {
        Text(this.isNetworking ? '🟢' : '⚫').fontSize(40)
        Text(this.isNetworking ? '已组网' : '未组网').fontSize(48).fontColor('#E8E8E8')
      }
      .width('100%').padding(24).backgroundColor('#252540').margin(22).borderRadius(16)

      Text('附近设备').fontSize(42).fontColor('#888888')
        .width('100%').padding({ left: 22, top: 16, bottom: 10 })

      Column({ space: 0 }) {
        ForEach(this.devices, (dev: DeviceInfo) => {
          Row({ space: 18 }) {
            Row() {
              Text(dev.type === '手机' ? '📱' : dev.type === '平板' ? '📋' : '💻').fontSize(56)
            }
            .width(96).height(96).borderRadius(22).backgroundColor('#353550')
            .justifyContent(FlexAlign.Center)

            Column({ space: 4 }) {
              Text(dev.name).fontSize(48).fontColor('#E8E8E8')
              Text(`${dev.type} · ${dev.online ? '在线' : '离线'}`)
                .fontSize(34).fontColor(dev.online ? '#4CAF50' : '#888888')
            }
            .alignItems(HorizontalAlign.Start).layoutWeight(1)

            if (dev.online) {
              Text('连接 >').fontSize(40).fontColor('#E8C575')
            }
          }
          .width('100%').height(140).padding({ left: 34, right: 34 })
          .border({ width: { bottom: 0.5 }, color: '#2A2A40' })
        })
      }.width('100%')

      Column({ space: 16 }) {
        Button(this.isNetworking ? '断开组网' : '开始组网')
          .width('85%').height(104).fontSize(48).fontColor('#333333')
          .backgroundColor('#E8C575').borderRadius(36)
          .onClick(() => { this.isNetworking = !this.isNetworking })

        Text('提示：组网后可将音乐流转到其他设备播放')
          .fontSize(34).fontColor('#666666')
      }
      .width('100%').margin({ top: 44 })

      Blank()
    }
    .width('100%').height('100%').backgroundColor('#1A1A2E')
  }
}
