import router from '@ohos.router'

@Entry
@Component
struct AdPage {
  @State countdown: number = 5
  private timer?: number

  aboutToAppear(): void {
    this.timer = setInterval(() => {
      this.countdown--
      if (this.countdown <= 0) {
        this.goToIndex()
      }
    }, 1000)
  }

  aboutToDisappear(): void {
    if (this.timer !== undefined) {
      clearInterval(this.timer)
    }
  }

  private goToIndex(): void {
    if (this.timer !== undefined) {
      clearInterval(this.timer)
      this.timer = undefined
    }
    router.replaceUrl({ url: 'pages/Index' })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        Column({ space: 52 }) {
          Image($rawfile('open screen1.png'))
            .width('100%').height("100%")


          Text('云音乐')
            .fontSize(72)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')

          Text('发现属于你的专属音乐')
            .fontSize(46)
            .fontColor('#AAAAAA')

          Text('海量正版音乐 · 无损音质 · 个性推荐')
            .fontSize(38)
            .fontColor('#888888')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#1A1A2E')

      Row() {
        Blank()
        Text(`${this.countdown}s 跳过`)
          .fontSize(40)
          .fontColor('#ff262626')
          .padding({ left: 30, right: 30, top: 16, bottom: 16 })
          .backgroundColor('#33FFFFFF')
          .borderRadius(30)
          .onClick(() => { this.goToIndex() })
      }
      .width('100%')
      .padding({ top: 34, right: 34 })
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1A1A2E')
  }
}
