import mediaquery from '@ohos.mediaquery'
import router from '@ohos.router'
import { getLoginState, clearLoginState, loadTheme, saveTheme } from '../common/PreferencesUtil'
import { player, SongItem } from '../common/AudioPlayerUtil'
import { PlaylistDrawer } from '../common/PlaylistDrawer'
import { BannerCard, Album, HotSong, Song, Artist } from '../model/model'


@Entry
@Component
struct Index {
  @State currentTab: number = 0
  @State currentCate: number = 0
  @State isLandscape: boolean = false
  @State showDrawer: boolean = false
  @State currentTheme: string = 'dark'
  @State loggedIn: boolean = false
  @State nickName: string = ''
  @State miniSongName: string = ''
  @State miniArtist: string = ''
  @State miniPlaying: boolean = false
  @State miniCover: ResourceStr = ''
  @State isFavorited: boolean = false
  @State showPlaylistDrawer: boolean = false
  @State drawerSongs: SongItem[] = []
  private mediaQueryListener?: mediaquery.MediaQueryListener

  private isDark(): boolean {
    return this.currentTheme !== 'light'
  }

  private bgColor(): string {
    return this.isDark() ? '#1A1A2E' : '#FFFFFF'
  }

  private surfaceColor(): string {
    return this.isDark() ? '#252540' : '#FFFFFF'
  }

  private textPrimary(): string {
    return this.isDark() ? '#E8E8E8' : '#111111'
  }

  private textBody(): string {
    return this.isDark() ? '#CCCCCC' : '#333333'
  }

  private textSecondary(): string {
    return this.isDark() ? '#888888' : '#999999'
  }

  private dividerColor(): string {
    return this.isDark() ? '#2A2A40' : '#E6E6E6'
  }

  private searchBgColor(): string {
    return this.isDark() ? '#25FFFFFF' : '#F2F3F5'
  }

  private vipBgColor(): string {
    return this.isDark() ? '#353550' : '#FFF3D8'
  }

  private vipTextColor(): string {
    return this.isDark() ? '#E8C575' : '#8A5B00'
  }

  private async toggleTheme(): Promise<void> {
    const next = this.isDark() ? 'light' : 'dark'
    this.currentTheme = next
    AppStorage.setOrCreate('theme', next)
    await saveTheme(getContext(this), next)
  }

  // ==================== 数据 ====================
  private bottomTabs: string[] = ['推荐', '发现', '漫游', '笔记', '我的']
  private categories: string[] = ['欧美热歌榜', '每日推荐', '私人雷达', '新歌首发']
  private bannerCards: BannerCard[] = [
    { title: '每日推荐', desc: '今日限定好歌推荐', image: $rawfile('open screen1.png') } as BannerCard,
    { title: '私人雷达', desc: '你爱的歌值得反复聆听', image: $rawfile('06.png') } as BannerCard,
    { title: '欧美热歌榜', desc: '最新单曲抢鲜先上线', image: $rawfile('4.png') } as BannerCard,
    { title: '新歌首发', desc: '最新单曲抢鲜先上线', image: $rawfile('bg1.png') } as BannerCard,
  ]
  private albums: Album[] = [
    { title: '私人雷达', plays: '4.6万', cover: $rawfile('6.png') } as Album,
    { title: '新歌雷达', plays: '122万', cover: $rawfile('7.png') } as Album,
    { title: '宝藏雷达', plays: '8.3万', cover: $rawfile('001.png') } as Album,
    { title: '时光雷达', plays: '56万', cover: $rawfile('002.png') } as Album,
    { title: '心动雷达', plays: '23万', cover: $rawfile('003.png') } as Album,
  ]
  private hotSongs: HotSong[] = [
    { name: '落了白', artist: '蒋雪儿Snow.J', quality: 'Hi-Res', cover: $rawfile('004.png') } as HotSong,
    { name: '远远的她', artist: '张学友', quality: 'Hi-Res', cover: $rawfile('005.png') } as HotSong,
    { name: '转身即心痛', artist: '谭维维，黄子弘凡', quality: 'Hi-Res', cover: $rawfile('006.png') } as HotSong,
    { name: '等你下课', artist: '周杰伦', quality: 'Hi-Res', cover: $rawfile('007.png') } as HotSong,
    { name: '罗生门', artist: '张子豪', quality: 'Hi-Res', cover: $rawfile('3.png') } as HotSong,
  ]
   private songs: Song[] = [
    { name: '佛系少女', artist: '张学友', quality: 'Hi-Res' } as Song,
    { name: 'The Niichts', artist: '薛之谦', quality: '' } as Song,
    { name: 'Beethoven Variations', artist: '谭维维', quality: 'Hi-Res' } as Song,
    { name: '乡村音乐集', artist: '黄子弘凡', quality: '' } as Song,
    { name: '转身即心痛', artist: '郭静', quality: '' } as Song,
    { name: '下一个天亮', artist: '蒋雪儿SnoW.J', quality: 'Hi-Res' } as Song,
    { name: '演员', artist: '林俊杰', quality: '' } as Song,
    { name: '遥远的她', artist: '张学友', quality: '' } as Song,
  ]
  private artists: Artist[] = [
    { name: '周杰伦', cover: $rawfile('ZJL.PNG') } as Artist,
    { name: '林俊杰', cover: $rawfile('LZJ.png') } as Artist,
    { name: '薛之谦', cover: $rawfile('003.png') } as Artist,
    { name: '华晨宇', cover: $rawfile('HCY.png') } as Artist,
    { name: '谭维维', cover: $rawfile('5.png') } as Artist,
    { name: '黄子弘凡', cover: $rawfile('6.png') } as Artist,
  ]
  private services: string[] = ['音乐闹钟', '定时关闭', '音乐云盘', '听歌免流']

  // ==================== 横竖屏 ====================
  aboutToAppear(): void {
    this.loadLoginState()
    this.currentTheme = AppStorage.get('theme') as string || 'dark'
    player.initContext(getContext(this))
    player.subscribe(this.refreshMini)
    this.refreshMini()
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

  onPageShow(): void {
    this.loadLoginState()
    this.currentTheme = AppStorage.get('theme') as string || 'dark'
  }

  private async loadLoginState(): Promise<void> {
    const state = await getLoginState(getContext(this))
    if (state) {
      this.loggedIn = true
      this.nickName = state.nick
    } else {
      this.loggedIn = false
      this.nickName = ''
    }
  }

  private refreshMini = (): void => {
    const s = player.currentSong
    this.miniSongName = s ? s.name : ''
    this.miniArtist = s ? s.artist : ''
    this.miniPlaying = player.isPlaying
    this.miniCover = (s && s.cover) ? s.cover : ''
    this.isFavorited = player.isCurrentFavorite
    this.drawerSongs = [...player.playlist]
  }

  aboutToDisappear(): void {
    player.unsubscribe(this.refreshMini)
    try {
      if (this.mediaQueryListener) {
        this.mediaQueryListener.off('change')
      }
    } catch (e) {
    }
  }

  // ==================== 侧边抽屉菜单 ====================
  @Builder
  DrawerMenu() {
    Column() {
      if (this.loggedIn) {
        Row({ space: 18 }) {
          Row() {
            if (this.nickName) {
              Text(this.nickName.substring(0, 1)).fontSize(68).fontColor('#CCCCCC')
            } else {
              Image($rawfile('person.png')).width(68).height(68).objectFit(ImageFit.Contain)
            }
          }
          .width(132)

          .height(132)
          .borderRadius(66)
          .backgroundColor('#353550')
          .justifyContent(FlexAlign.Center)

          Column({ space: 6 }) {
            Text(this.nickName || '用户')
              .fontSize(46)
              .fontColor(this.textPrimary())
              .fontWeight(FontWeight.Medium)
            Text('查看个人主页 >')
              .fontSize(34)
              .fontColor(this.textSecondary())
          }
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({ left: 24, top: 56, bottom: 24 })
        .onClick(() => {
          this.showDrawer = false
          router.pushUrl({ url: 'pages/PersonalInfo' })
        })
      } else {
        Row({ space: 18 }) {
          Row() {
            Image($rawfile('person.png')).width(68).height(68).objectFit(ImageFit.Contain)
          }
          .width(132)
          .height(132)
          .borderRadius(66)
          .backgroundColor('#353550')
          .justifyContent(FlexAlign.Center)

          Column({ space: 6 }) {
            Text('立即登录')
              .fontSize(46)
              .fontColor(this.textPrimary())
              .fontWeight(FontWeight.Medium)
            Text('登录后享受更多功能')
              .fontSize(34)
              .fontColor(this.textSecondary())
          }
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({ left: 24, top: 56, bottom: 24 })
        .onClick(() => {
          this.showDrawer = false
          router.pushUrl({ url: 'pages/Login' })
        })
      }

      Row() {
      }.width('100%').height(1).backgroundColor(this.dividerColor())

      Scroll() {
        Column({ space: 0 }) {
          this.DrawerItem('专辑', '')
          this.DrawerItem('开通黑胶VIP', '首月仅5元')
          this.DrawerItem('SVIP/VIP', '享超21项特权 >')
          this.DrawerItem('我的消息', '')
          this.DrawerItem('云村有票', '')
          this.DrawerItem('我的订单', '')
          this.DrawerItem('音乐服务', '音乐闹钟·定时关闭·云盘·免流 >')
          this.DrawerItem('游戏专区', '')
          this.DrawerItem('更多', '')
          this.DrawerItem('设置', '')
          Row({ space: 12 }) {
            Text('夜间模式')
              .fontSize(42)
              .fontColor(this.textBody())
              .layoutWeight(1)
            Text(this.isDark() ? ' 开' : ' 关')
              .fontSize(34)
              .fontColor(this.textSecondary())
          }
          .width('100%')
          .height(112)
          .padding({ left: 24, right: 24 })
          .onClick(async () => {
            await this.toggleTheme()
          })
 
          Row({ space: 12 }) {
            Text('退出登录')
              .fontSize(42)
              .fontColor('#FF6B6B')
              .layoutWeight(1)
          }
          .width('100%')
          .height(112)
          .padding({ left: 24, right: 24 })
          .onClick(async () => {
            this.showDrawer = false
            await clearLoginState(getContext(this))
            this.loggedIn = false
            this.nickName = ''
          })
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bgColor())
  }

  @Builder
  DrawerItem(label: string, sub: string) {
    Row({ space: 12 }) {
      Text(label)
        .fontSize(42)
        .fontColor(this.textBody())
        .layoutWeight(1)
      if (sub !== '') {
        Text(sub)
          .fontSize(34)
          .fontColor(this.textSecondary())
          .maxLines(1)
      }
    }
    .width('100%')
    .height(112)
    .padding({ left: 24, right: 24 })
  }

  // ==================== 顶栏 ====================
  @Builder
  TopBar() {
    Row({ space: 14 }) {
      Row() {
        Image($rawfile('list_bullet.png'))
          .width(56)
          .height(56)
          .objectFit(ImageFit.Contain)
      }.width(80).height(80).justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.showDrawer = !this.showDrawer
      })

      Row({ space: 12 }) {
        Image($rawfile('搜索.png'))
          .width(42)
          .height(42)
          .objectFit(ImageFit.Contain)
        Text('搜索歌曲、歌手、专辑')
          .fontSize(40)
          .fontColor(this.textSecondary())
          .maxLines(1)
      }
      .layoutWeight(1)
      .height(84)
      .padding({ left: 26, right: 26 })
      .borderRadius(42)
      .backgroundColor(this.searchBgColor())

      Text('SVIP VIP享超21项特权>')
        .fontSize(32)
        .fontColor(this.vipTextColor())
        .padding({ left: 20, right: 20, top: 14, bottom: 14 })
        .borderRadius(30)
        .backgroundColor(this.vipBgColor())

      Image($rawfile('麦克风.png'))
        .width(56)
        .height(56)
        .objectFit(ImageFit.Contain)
    }
    .width('100%')
    .height(112)
    .padding({ left: 30, right: 30, top: 14, bottom: 14 })
  }

  // ==================== VIP 推广条 ====================
  @Builder
  VipPromo() {
    Row({ space: 12 }) {
      Text('SVIP')
        .fontSize(34)
        .fontColor('#3D2614')
        .fontWeight(FontWeight.Bold)
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .backgroundColor('#E8C575')
        .borderRadius(5)
      Text('VIP享超21项特权')
        .fontSize(42)
        .fontColor('#E8C575')
        .layoutWeight(1)
      Text('>')
        .fontSize(42)
        .fontColor('#E8C575')
    }
    .width('100%')
    .height(88)
    .padding({ left: 22, right: 22 })
  }

  // ==================== 分类标签 ====================
  @Builder
  CategoryTabs() {
    Row({ space: 0 }) {
      ForEach(this.categories, (cate: string, index: number) => {
        Column() {
          Text(cate)
            .fontSize(index === this.currentCate ? 50 : 42)
            .fontWeight(index === this.currentCate ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(index === this.currentCate ? this.textPrimary() : this.textSecondary())
          if (index === this.currentCate) {
            Row() {
            }
            .width(52)
            .height(7)
            .borderRadius(4)
            .backgroundColor('#E8C575')
            .margin({ top: 6 })
          }
        }
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          this.currentCate = index
        })
      })
    }
    .width('100%')
    .padding({ left: 6, right: 6 })
  }

  // ==================== 横向滚动专辑卡片 ====================
  @Builder
  BannerScroll() {
    Column({ space: 24 }) {
      Row() {
        Text(this.loggedIn ? `下午好，${this.nickName}` : '下午好')
          .fontSize(60)
          .fontColor(this.textPrimary())
          .fontWeight(FontWeight.Bold)
        Blank()
      }
      .width('100%')
      .padding({ left: 22, right: 22, top: 10 })

      List({ space: 24 }) {
        ForEach(this.bannerCards, (item: BannerCard) => {
          ListItem() {
            Stack({ alignContent: Alignment.BottomStart }) {
              Image(item.image)
                .width(420)
                .height(240)
                .borderRadius(26)
                .objectFit(ImageFit.Cover)

              Column({ space: 6 }) {
                Text(item.title)
                  .fontSize(46)
                  .fontColor('#FFFFFF')
                  .fontWeight(FontWeight.Bold)
                Text(item.desc)
                  .fontSize(34)
                  .fontColor('#F2F2F2')
                  .maxLines(1)
              }
              .padding({ left: 16, right: 16, bottom: 16 })
            }
            .width(420)
            .height(240)
            .onClick(() => {
              router.pushUrl({
                url: 'pages/PlaylistDetail',
                params: { name: item.title, desc: item.desc, cover: item.image }
              })
            })
          }
        })
      }
      .listDirection(Axis.Horizontal)
      .width('100%')
      .height(260)
      .padding({ left: 22 })
      .scrollBar(BarState.Off)
    }
    .width('100%')
  }

  @Builder
  AlbumScroll() {
    Column({ space: 16 }) {
      Row() {
        Text(`${(this.loggedIn && this.nickName) ? this.nickName : '我'}的雷达歌单`)
          .fontSize(52)
          .fontColor(this.textPrimary())
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('更多 >')
          .fontSize(40)
          .fontColor(this.textSecondary())
      }
      .width('100%')
      .padding({ left: 22, right: 22 })

      List({ space: 18 }) {
        ForEach(this.albums, (item: Album) => {
          ListItem() {
            Column({ space: 12 }) {
              Stack({ alignContent: Alignment.TopStart }) {
                Image(item.cover)
                  .width(280)
                  .height(280)
                  .borderRadius(26)
                  .objectFit(ImageFit.Cover)

                Row({ space: 6 }) {
                  Image($rawfile('play_fill.png'))
                    .width(32)
                    .height(32)
                    .objectFit(ImageFit.Contain)
                  Text(item.plays)
                    .fontSize(34)
                    .fontColor('#FFFFFF')
                    .fontWeight(FontWeight.Medium)
                }
                .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                .borderRadius(16)
                .backgroundColor('#66000000')
                .offset({ x: 10, y: 10 })
              }
              .width(280)
              .height(280)
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/PlaylistDetail',
                  params: { name: item.title, cover: item.cover }
                })
              })

              Text(item.title)
                .fontSize(40)
                .fontColor(this.textBody())
                .maxLines(1)
                .width(280)
            }
            .width(280)
          }
        })
      }
      .listDirection(Axis.Horizontal)
      .width('100%')
      .height(360)
      .padding({ left: 22 })
      .scrollBar(BarState.Off)
    }
    .width('100%')
  }

  @Builder
  HotSongScroll() {
    Column({ space: 16 }) {
      Row() {
        Text('热门歌曲推荐')
          .fontSize(52)
          .fontColor(this.textPrimary())
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('更多 >')
          .fontSize(40)
          .fontColor(this.textSecondary())
      }
      .width('100%')
      .padding({ left: 22, right: 22 })

      List({ space: 18 }) {
        ForEach(this.hotSongs, (item: HotSong) => {
          ListItem() {
            Column({ space: 12 }) {
              Stack({ alignContent: Alignment.BottomStart }) {
                Image(item.cover)
                  .width(280)
                  .height(280)
                  .borderRadius(26)
                  .objectFit(ImageFit.Cover)
                if (item.quality !== '') {
                  Text(item.quality)
                    .fontSize(30)
                    .fontColor('#FF3B30')
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .borderRadius(10)
                    .backgroundColor('#26FFFFFF')
                    .margin({ left: 10, bottom: 10 })
                }
              }
              .width(280)
              .height(280)

              Text(item.name)
                .fontSize(40)
                .fontColor(this.textBody())
                .maxLines(1)
                .width(280)
              Text(item.artist)
                .fontSize(34)
                .fontColor(this.textSecondary())
                .maxLines(1)
                .width(280)
            }
            .width(280)
          }
        })
      }
      .listDirection(Axis.Horizontal)
      .width('100%')
      .height(410)
      .padding({ left: 22 })
      .scrollBar(BarState.Off)
    }
    .width('100%')
  }

  // ==================== 歌曲列表 ====================
  @Builder
  SongList() {
    Column({ space: 0 }) {
      ForEach(this.songs, (item: Song, index: number) => {
        Row({ space: 24 }) {
          Text(`${index + 1}`)
            .fontSize(40)
            .fontColor(this.textSecondary())
            .width(64)
            .textAlign(TextAlign.Center)

          Column({ space: 8 }) {
            Row({ space: 10 }) {
              Text(item.name)
                .fontSize(50)
                .fontColor(this.textPrimary())
                .fontWeight(FontWeight.Medium)
                .maxLines(1)
              if (item.quality !== '') {
                Text(item.quality)
                  .fontSize(28)
                  .fontColor('#E8C575')
                  .padding({ left: 5, right: 5, top: 2, bottom: 2 })
                  .border({ width: 1, color: '#E8C575' })
                  .borderRadius(3)
              }
            }

            Text(item.artist)
              .fontSize(36)
              .fontColor(this.textSecondary())
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text('>')
            .fontSize(42)
            .fontColor(this.textSecondary())
        }
        .width('100%')
        .height(132)
        .padding({ left: 22, right: 22 })
      })
    }
    .width('100%')
  }

  // ==================== 猜你喜欢的歌手 ====================
  @Builder
  ArtistScroll() {
    Column({ space: 16 }) {
      Row() {
        Text('猜你喜欢的歌手')
          .fontSize(50)
          .fontColor(this.textPrimary())
          .fontWeight(FontWeight.Bold)
        Blank()
      }
      .width('100%')
      .padding({ left: 22, right: 22 })

      List({ space: 20 }) {
        ForEach(this.artists, (item: Artist) => {
          ListItem() {
            Column({ space: 10 }) {
              Image(item.cover)
                .width(132)
                .height(132)
                .borderRadius(66)
                .objectFit(ImageFit.Cover)
              Text(item.name)
                .fontSize(36)
                .fontColor(this.textBody())
              Text('热门歌手')
                .fontSize(30)
                .fontColor(this.textSecondary())
            }
            .width(160)
            .alignItems(HorizontalAlign.Center)
          }
        })
      }
      .listDirection(Axis.Horizontal)
      .width('100%')
      .height(230)
      .padding({ left: 22 })
      .scrollBar(BarState.Off)
    }
    .width('100%')
  }

  // ==================== 音乐服务 ====================
  @Builder
  MusicServices() {
    Column({ space: 12 }) {
      Text('音乐服务')
        .fontSize(50)
        .fontColor(this.textPrimary())
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ left: 22, right: 22 })

      Grid() {
        ForEach(this.services, (name: string) => {
          GridItem() {
            Row() {
              Text(name)
                .fontSize(42)
                .fontColor(this.textBody())
            }
            .width('100%')
            .height(104)
            .borderRadius(12)
            .backgroundColor(this.isDark() ? '#1E1E30' : '#F2F3F5')
            .justifyContent(FlexAlign.Center)

          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .width('100%')
      .padding({ left: 22, right: 22 })
    }
    .width('100%')
    .height(200)
  }

  // ==================== 底部导航（5个Tab） ====================
  @Builder
  BottomNav() {
    Row() {
      ForEach(this.bottomTabs, (tab: string, index: number) => {
        Column({ space: 8 }) {
          Text(tab)
            .fontSize(44)
            .fontColor(index === this.currentTab ? '#E8C575' : this.textSecondary())
          if (index === this.currentTab) {
            Row() {
            }
            .width(42)
            .height(7)
            .borderRadius(2)
            .backgroundColor('#E8C575')
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 12, bottom: 10 })
        .onClick(() => {
          this.currentTab = index
        })
      })
    }
    .width('100%')
    .backgroundColor(this.bgColor())
  }

  // ==================== 迷你播放器 ====================
  @Builder
  MiniPlayer() {
    Row({ space: 22 }) {
      // 小封面 — 点击进入 FullPlayer
      Row() {
        if (this.miniCover) {
          Image(this.miniCover)
            .width(88).height(88).borderRadius(16).objectFit(ImageFit.Cover)
        } else {
          Image($rawfile('music.png'))
            .width(46).height(46).objectFit(ImageFit.Contain)
        }
      }
      .width(88)
      .height(88)
      .borderRadius(16)
      .backgroundColor(this.isDark() ? '#353550' : '#F2F3F5')
      .justifyContent(FlexAlign.Center)
      .onClick(() => { router.pushUrl({ url: 'pages/FullPlayer' }) })

      // 歌名+歌手 — 点击进入 FullPlayer
      Column({ space: 4 }) {
        Text(this.miniSongName || '未播放歌曲')
          .fontSize(44)
          .fontColor(this.textPrimary())
          .maxLines(1)
        Text(this.miniArtist || '')
          .fontSize(32)
          .fontColor(this.textSecondary())
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .onClick(() => { router.pushUrl({ url: 'pages/FullPlayer' }) })

      Row({ space: 28 }) {
        // 爱心
        Image(this.isFavorited ? $rawfile('heart_fill.png') : $rawfile('heart.png'))
          .width(48).height(48).objectFit(ImageFit.Contain)
          .onClick(() => { player.toggleCurrentFavorite() })

        Row() {
          Image(this.miniPlaying ? $rawfile('pause_round_triangle_fill.png') : $rawfile('play_circle_fill.png'))
            .width(54).height(54).objectFit(ImageFit.Contain)
        }.width(80).height(80).justifyContent(FlexAlign.Center)
        .onClick(() => {
          if (player.hasSong) {
            player.togglePlay()
          } else {
            router.pushUrl({ url: 'pages/PlaylistDetail' })
          }
        })

        Row() {
          Image($rawfile('forward_end_fill.png'))
            .width(48).height(48).objectFit(ImageFit.Contain)
        }.width(80).height(80).justifyContent(FlexAlign.Center)
        .onClick(() => {
          player.next()
        })

        // 播放列表 — 弹出抽屉
        Row() {
          Image($rawfile('music_note_list.png'))
            .width(48).height(48).objectFit(ImageFit.Contain)
        }.width(80).height(80).justifyContent(FlexAlign.Center)
        .onClick(() => { this.showPlaylistDrawer = !this.showPlaylistDrawer })
      }
    }
    .width('100%')
    .height(116)
    .padding({ left: 30, right: 30 })
    .backgroundColor(this.surfaceColor())
  }

  // ==================== "发现"页面 ====================
  @Builder
  DiscoverContent() {
    Scroll() {
      Column({ space: 0 }) {
        Text('热门话题')
          .fontSize(50)
          .fontColor(this.textPrimary())
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .padding({ left: 22, top: 18, bottom: 12 })
        ForEach(['#今日推荐歌单', '#新歌速递', '#热门翻唱', '#独立音乐人', '#演唱会现场', '#每日推荐'], (tag: string) => {
          Row() {
            Text(tag).fontSize(42).fontColor(this.isDark() ? '#7B9EFF' : '#3D7DFF')
            Blank()
            Text('>').fontSize(42).fontColor(this.textSecondary())
          }
          .width('100%').height(112).padding({ left: 34, right: 34 })
          .border({ width: { bottom: 0.5 }, color: this.dividerColor() })
        })
        Blank().height(20)
      }.width('100%')
    }
    .width('100%').layoutWeight(1).scrollBar(BarState.Off).edgeEffect(EdgeEffect.None)
  }

  // ==================== "我的"页面 ====================
  @Builder
  MineContent() {
    Scroll() {
      Column({ space: 0 }) {
        Row({ space: 18 }) {
          Row() {
            if (this.loggedIn && this.nickName) {
              Text(this.nickName.substring(0, 1)).fontSize(68).fontColor('#CCCCCC')
            } else {
              Image($rawfile('person.png')).width(68).height(68).objectFit(ImageFit.Contain)
            }
          }
          .width(132)
          .height(132)
          .borderRadius(66)
          .backgroundColor('#353550')
          .justifyContent(FlexAlign.Center)

          Column({ space: 6 }) {
            Text(this.loggedIn ? this.nickName : '未登录')
              .fontSize(52).fontColor(this.textPrimary()).fontWeight(FontWeight.Bold)
            Text(this.loggedIn ? '查看我的主页 >' : '登录后享受更多功能')
              .fontSize(38).fontColor(this.textSecondary())
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)

          if (this.loggedIn) {
            Text('编辑')
              .fontSize(38)
              .fontColor('#E8C575')
              .padding({ left: 16, right: 16, top: 6, bottom: 6 })
              .border({ width: 1, color: '#E8C575' })
              .borderRadius(16)
              .onClick(() => {
                router.pushUrl({ url: 'pages/PersonalEdit' })
              })
          }
        }
        .width('100%').padding(24)
        .onClick(() => {
          if (this.loggedIn) router.pushUrl({ url: 'pages/PersonalInfo' })
          else router.pushUrl({ url: 'pages/Login' })
        })

        Row() {
        }.width('100%').height(10).backgroundColor(this.isDark() ? '#0A0A18' : '#F2F3F5')

        Column({ space: 0 }) {
          Row({ space: 12 }) {
            Text('我的收藏').fontSize(46).fontColor(this.textPrimary())
            Blank()
            Text('>').fontSize(42).fontColor(this.textSecondary())
          }
          .width('100%').height(112).padding({ left: 34, right: 34 })
          .border({ width: { bottom: 0.5 }, color: this.dividerColor() })
          .onClick(() => {
            router.pushUrl({ url: 'pages/Favorites' })
          })
          this.MineMenuItem('最近播放', '')
          this.MineMenuItem('下载管理', '')
          this.MineMenuItem('音乐服务', '闹钟·定时·云盘·免流')
          Row({ space: 12 }) {
            Text('主题设置').fontSize(46).fontColor(this.textPrimary())
            Blank()
            Text('>').fontSize(42).fontColor(this.textSecondary())
          }
          .width('100%')
          .height(112)
          .padding({ left: 24, right: 24 })
          .border({ width: { bottom: 0.5 }, color: this.dividerColor() })
          .onClick(() => {
            router.pushUrl({ url: 'pages/ThemeSettings' })
          })

          this.MineMenuItem('设置', '')
        }.width('100%')

        Row() {
        }.width('100%').height(10).backgroundColor(this.isDark() ? '#0A0A18' : '#F2F3F5')

        if (this.loggedIn) {
          Row() {
            Text('退出登录').fontSize(46).fontColor('#FF6B6B')
          }
          .width('100%').height(112).justifyContent(FlexAlign.Center)
          .onClick(async () => {
            await clearLoginState(getContext(this))
            this.loggedIn = false
            this.nickName = ''
          })
        }
        Blank().height(20)
      }.width('100%')
    }
    .width('100%').layoutWeight(1).scrollBar(BarState.Off).edgeEffect(EdgeEffect.None)
  }

  @Builder
  MineMenuItem(label: string, hint: string) {
    Row({ space: 12 }) {
      Text(label).fontSize(46).fontColor(this.textPrimary())
      if (hint !== '') Text(hint).fontSize(36).fontColor(this.textSecondary()).maxLines(1)
      Blank()
      Text('>').fontSize(42).fontColor(this.textSecondary())
    }
    .width('100%').height(112).padding({ left: 34, right: 34 })
    .border({ width: { bottom: 0.5 }, color: this.dividerColor() })
  }

  // ==================== 占位 ====================
  @Builder
  TabPlaceholder(title: string) {
    Column() {
      Text(title).fontSize(54).fontColor(this.textSecondary())
    }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
  }

  // ==================== 首页内容区 ====================
  @Builder
  MainContent() {
    Scroll() {
      Column({ space: 24 }) {
        this.BannerScroll()
        this.AlbumScroll()
        this.HotSongScroll()
        this.ArtistScroll()
        this.MusicServices()
        // Blank()
      }

      .width('100%')
      .padding({ top: 12 ,bottom:20 })
    }
    .width('100%')
     .layoutWeight(1)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.None)
  }

  // 播放列表只覆盖大页面内容，MiniPlayer 始终在它前面
  @Builder
  ContentWithPlaylist() {
    Stack() {
      Column() {
        if (this.currentTab === 0) {
          this.MainContent()
        }
        else if (this.currentTab === 1) {
          this.DiscoverContent()
        }
        else if (this.currentTab === 2) {
          this.TabPlaceholder('漫游')
        }
        else if (this.currentTab === 3) {
          this.TabPlaceholder('笔记')
        }
        else {
          this.MineContent()
        }
      }
      .width('100%').height('100%')

      PlaylistDrawer({
        show: this.showPlaylistDrawer,
        songs: this.drawerSongs,
        currentSongName: this.miniSongName,
        onClose: () => { this.showPlaylistDrawer = false }
      })
    }
    .width('100%').layoutWeight(1).clip(true)
  }

  @Builder
  MainBody() {
    if (!this.isLandscape) { // <-- 竖屏时使用左侧导航栏
      Row() {
        // 左侧导航栏
        Column({ space: 24 }) {
          ForEach(this.bottomTabs, (tab: string, index: number) => {
            Column({ space: 4 }) {
              Text(tab.substring(0, 1)).fontSize(48)
                .fontColor(index === this.currentTab ? '#E8C575' : this.textSecondary())
              Text(tab).fontSize(30)
                .fontColor(index === this.currentTab ? '#E8C575' : this.textSecondary())
            }.padding({ top: 8, bottom: 8 }).alignItems(HorizontalAlign.Center)
            .onClick(() => {
              this.currentTab = index
            })
          })
        }.width(150).height('100%').backgroundColor(this.surfaceColor()).padding({ top: 40 })

        // 右侧内容区
        Column() {
          this.TopBar()
          this.ContentWithPlaylist()
          this.MiniPlayer()
        }.layoutWeight(1).height('100%')
      }.width('100%').height('100%').backgroundColor(this.bgColor())
    } else { // <-- 横屏时使用底部导航栏
      Column() {
        this.TopBar()
        this.ContentWithPlaylist()
        this.MiniPlayer()
        this.BottomNav()
      }.width('100%').height('100%').backgroundColor(this.bgColor())
    }
  }

  // ==================== 主布局 ====================
  build() {
    Stack() {
      this.MainBody()

      if (this.showDrawer) {
        Row() {
          Column() {
            this.DrawerMenu()
          }
          .width('75%').height('100%')
          .shadow({ radius: 12, color: '#00000040', offsetX: 4, offsetY: 0 })

          Column() {
          }
          .width('25%').height('100%')
          .backgroundColor('#99000000')
          .onClick(() => {
            this.showDrawer = false
          })
        }
        .width('100%').height('100%')
      }
    }
    .width('100%').height('100%')
    .backgroundColor(this.bgColor())
  }
}
