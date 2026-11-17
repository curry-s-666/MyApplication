import router from '@ohos.router';
import { setGuideShown } from '../common/PreferencesUtil';

interface GuideItem {
  title: string
  description: string
  image: ResourceStr
}

@Entry
@Component
struct Guide {
  private guideData: GuideItem[] = [
    {
      title: '发现好音乐',
      description: '海量音乐资源，随时随地发现你的专属音乐',
      image: $rawfile('open screen1.png')
    },
    {
      title: '个性化推荐',
      description: '基于你的喜好，智能推荐最适合的音乐',
      image: $rawfile('6.png')
    },
    {
      title: '更多精彩',
      description: '探索更多音乐世界',
      image: $rawfile('7.png')
    }
  ]

  @State currentIndex: number = 0

  private skipGuide(): void {
    setGuideShown(getContext(this), true);
    router.replaceUrl({ url: 'pages/AdPage' });
  }

  private async finishGuide(): Promise<void> {
    await setGuideShown(getContext(this), true);
    router.replaceUrl({ url: 'pages/AdPage' });
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Swiper() {
        ForEach(this.guideData, (item: GuideItem, index: number) => {
          Column({ space: 36 }) {
            Image(item.image)
              .width('75%')
              .height('45%')
              .objectFit(ImageFit.Contain)

            Text(item.title)
              .fontSize(60)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1F1F1F')

            Text(item.description)
              .fontSize(42)
              .fontColor('#6B6B6B')
              .textAlign(TextAlign.Center)
              .padding({ left: 48, right: 48 })

            if (index === this.guideData.length - 1) {
              Button('开始体验')
                .width('75%')
                .height(104)
                .backgroundColor('#3D7DFF')
                .fontColor('#FFFFFF')
                .fontSize(48)
                .fontWeight(FontWeight.Medium)
                .borderRadius(52)
                .margin({ top: 32 })
                .onClick(() => {
                  this.finishGuide();
                })
            }
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        }, (item: GuideItem, index: number) => `${index}-${item.title}`)
      }
      .index(this.currentIndex)
      .loop(false)
      .indicator(false)
      .width('100%')
      .height('100%')
      .onChange((index: number) => {
        this.currentIndex = index;
      })

      // 指示器导航点 - 底部居中
      Row({ space: 18 }) {
        ForEach(this.guideData, (_: GuideItem, dotIndex: number) => {
          Row() {}
            .width(dotIndex === this.currentIndex ? 40 : 20)
            .height(20)
            .borderRadius(10)
            .backgroundColor(dotIndex === this.currentIndex ? '#3D7DFF' : '#CCCCCC')
            .animation({ duration: 200, curve: Curve.EaseInOut })
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .align(Alignment.Bottom)
      .margin({ bottom: 140 })

      // 跳过按钮 - 仿照 AdPage 的右上角布局
      Row() {
        Blank()
        Text('跳过')
          .fontSize(40)
          .fontColor('#6B6B6B')
          .padding({ left: 30, right: 30, top: 16, bottom: 16 })
          .backgroundColor('#F2F2F2')
          .borderRadius(30)
          .onClick(() => {
            this.skipGuide();
          })
      }
      .width('100%')
      .padding({ top: 34, right: 34 })
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
