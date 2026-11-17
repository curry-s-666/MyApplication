import router from '@ohos.router'
import { saveTheme } from '../common/PreferencesUtil'

@Entry
@Component
struct ThemeSettings {
  @StorageProp('theme') currentTheme: string = 'dark'

  private isDark(): boolean { return this.currentTheme !== 'light' }
  private bgColor(): string { return this.isDark() ? '#1A1A2E' : '#FFFFFF' }
  private textPrimary(): string { return this.isDark() ? '#E8E8E8' : '#111111' }
  private textSecondary(): string { return this.isDark() ? '#888888' : '#999999' }
  private dividerColor(): string { return this.isDark() ? '#2A2A40' : '#E6E6E6' }

  private setTheme(name: string): void {
    this.currentTheme = name
    AppStorage.setOrCreate('theme', name)
    saveTheme(getContext(this), name)
  }

  build() {
    Column({ space: 0 }) {
      Row() {
        Text('‹').fontSize(60).fontColor(this.textPrimary()).onClick(() => { router.back() })
        Blank()
        Text('主题设置').fontSize(50).fontColor(this.textPrimary()).fontWeight(FontWeight.Bold)
        Blank()
        Text('').width(32)
      }
      .width('100%').height(112).padding({ left: 34, right: 34 })

      Column({ space: 0 }) {
        Row({ space: 18 }) {
          Image($rawfile('moon_fill.png')).width(60).height(60).objectFit(ImageFit.Contain)
          Column({ space: 4 }) {
            Text('暗色模式').fontSize(48).fontColor(this.textPrimary())
            Text('深邃背景，夜间更护眼').fontSize(34).fontColor(this.textSecondary())
          }.alignItems(HorizontalAlign.Start)
          Blank()
          Row() {
            Text(this.currentTheme === 'dark' ? '●' : '○')
              .fontSize(52).fontColor(this.currentTheme === 'dark' ? '#E8C575' : '#555555')
          }.width(60).height(60).justifyContent(FlexAlign.Center)
        }
        .width('100%').height(144).padding({ left: 34, right: 34 })
        .onClick(() => { this.setTheme('dark') })
        .border({ width: { bottom: 0.5 }, color: this.dividerColor() })

        Row({ space: 18 }) {
          Image($rawfile('sun_max_fill.png')).width(60).height(60).objectFit(ImageFit.Contain)
          Column({ space: 4 }) {
            Text('亮色模式').fontSize(48).fontColor(this.textPrimary())
            Text('清爽明亮，白天更清晰').fontSize(34).fontColor(this.textSecondary())
          }.alignItems(HorizontalAlign.Start)
          Blank()
          Row() {
            Text(this.currentTheme === 'light' ? '●' : '○')
              .fontSize(52).fontColor(this.currentTheme === 'light' ? '#E8C575' : '#555555')
          }.width(60).height(60).justifyContent(FlexAlign.Center)
        }
        .width('100%').height(144).padding({ left: 34, right: 34 })
        .onClick(() => { this.setTheme('light') })
        .border({ width: { bottom: 0.5 }, color: this.dividerColor() })
      }.width('100%')
    }
    .width('100%').height('100%').backgroundColor(this.bgColor())
  }
}
