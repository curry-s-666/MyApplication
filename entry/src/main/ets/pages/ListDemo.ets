//列表是一种复杂的容器，当列表项达到一定数量，内容超过屏幕大小时，
// 可以自动提供滚动功能。它适合用于呈现同类数据类型或数据类型集，
// 例如图片和文本。在列表中显示数据集合是许多应用程序中的常见要求
// （如通讯录、音乐列表、购物清单等）。
class UserInfo {
  avatar: ResourceStr
  nickName: string

  constructor(avatar: ResourceStr, nickName: string) {
    this.avatar = avatar
    this.nickName = nickName
  }
}

@Entry
@Component
struct ListDemo {
  @State userInfoArray: UserInfo[] = []

  //页面出现时执行的生命周期方法，可以在里面做一些初始化操作
  aboutToAppear(): void {
    for (let index = 0; index < 50; index++) {
      this.userInfoArray.push(new UserInfo($rawfile(`${index % 6 + 1}.png`),
        (2024090901000 + index).toString()))
    }
  }

  build() {

    List({ space: 20 }) {
      //ForEach的类型ForEachInterface的实现如下：
      //(arr: Array<any>, itemGenerator: (item: any, index: number) => void,
      // keyGenerator?: (item: any, index: number) => string): ForEachInterface;
      ForEach(
        this.userInfoArray, //被迭代的数组
        (item: UserInfo, index: number) => {
          //迭代器：item表示当前从数组中取出的元素，我们要根据实际的数据类型指定它的类型
          //index就是当前从数组中取出的元素的索引
          ListItem() {
            Row({ space: 20 }) {
              Image(item.avatar).width(100).aspectRatio(1).borderRadius(50)
              Text(item.nickName).fontSize(60)
            }
          }
        },
        (item: UserInfo, index) => index.toString()) //键生成器，作为当前子项的唯一标识)
    }
    .listDirection(Axis.Vertical)  //设置List的方向，默认是垂直方向Vertical

    //如果我们List列表中的数据量比较大，推荐使用LazyForEach或者Repeat，结合预加载，性能更好
  }
}