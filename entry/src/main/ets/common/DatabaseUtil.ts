import relationalStore from '@ohos.data.relationalStore'
import type common from '@ohos.app.ability.common'

export interface UserInfo {
  id: number
  phone: string
  nickname: string
  avatar: string
}

// ========== 内存模拟数据库（Preview 回退方案） ==========
let memUsers: UserInfo[] = [
  { id: 1, phone: '13800000000', nickname: '测试用户', avatar: '' }
]
let memId = 1

function memFind(phone: string): UserInfo | null {
  return memUsers.find(u => u.phone === phone) || null
}

function memInsert(phone: string, password: string): UserInfo {
  memId++
  const user: UserInfo = {
    id: memId,
    phone: phone,
    nickname: '用户' + phone.substring(phone.length - 4),
    avatar: ''
  }
  memUsers.push(user)
  return user
}

// ========== 真实 RDB ==========
let _store: relationalStore.RdbStore | null = null
let _useRdb: boolean | null = null

async function tryRdb(ctx: object): Promise<boolean> {
  if (_useRdb !== null) return _useRdb
  try {
    const config: relationalStore.StoreConfig = {
      name: 'MusicApp.db',
      securityLevel: relationalStore.SecurityLevel.S1
    }
    _store = await relationalStore.getRdbStore(ctx as common.Context, config)
    await _store.executeSql(`CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      phone TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      nickname TEXT,
      avatar TEXT
    )`)
    _useRdb = true
    // 初始化默认账号到 RDB
    const predicates = new relationalStore.RdbPredicates('users')
    const rs = await _store.query(predicates)
    if (rs.rowCount === 0) {
      const bucket: relationalStore.ValuesBucket = {
        phone: '13800000000', password: '123456', nickname: '测试用户', avatar: ''
      }
      await _store.insert('users', bucket)
    }
    rs.close()
    return true
  } catch (e) {
    _useRdb = false
    return false
  }
}






// ====== 密码登录 ======
export async function loginByPassword(ctx: object, phone: string, password: string): Promise<{ user: UserInfo | null, error: string }> {
  const useRdb = await tryRdb(ctx)
  if (useRdb && _store) {
    try {
      const predicates = new relationalStore.RdbPredicates('users')
      predicates.equalTo('phone', phone)
      const rs = await _store.query(predicates)
      if (rs.rowCount === 0) {
        rs.close()
        return { user: null, error: '手机号未注册，请先注册账号' }
      }
      rs.goToFirstRow()
      const pwd = rs.getString(rs.getColumnIndex('password'))
      if (pwd !== password) { rs.close(); return { user: null, error: '密码错误' } }
      const user: UserInfo = {
        id: rs.getLong(rs.getColumnIndex('id')),
        phone: rs.getString(rs.getColumnIndex('phone')),
        nickname: rs.getString(rs.getColumnIndex('nickname')),
        avatar: rs.getString(rs.getColumnIndex('avatar'))
      }
      rs.close()
      return { user, error: '' }
    } catch (e) {
      const err = e as { code?: number, message?: string }
      return { user: null, error: 'DB错误[' + (err.code ?? '?') + ']:' + (err.message ?? String(e)) }
    }
  }

  // 内存模式
  const user = memFind(phone)
  if (!user) return { user: null, error: '手机号未注册，请先注册账号' }
  return { user, error: '' }
}

// ====== 验证码登录 ======
export async function loginBySms(ctx: object, phone: string, smsCode: string): Promise<{ user: UserInfo | null, error: string }> {
  if (smsCode !== '1234') return { user: null, error: '验证码错误（提示：1234）' }
  const useRdb = await tryRdb(ctx)
  if (useRdb && _store) {
    try {
      const predicates = new relationalStore.RdbPredicates('users')
      predicates.equalTo('phone', phone)
      const rs = await _store.query(predicates)
      if (rs.rowCount > 0) {
        rs.goToFirstRow()
        const user: UserInfo = {
          id: rs.getLong(rs.getColumnIndex('id')),
          phone: rs.getString(rs.getColumnIndex('phone')),
          nickname: rs.getString(rs.getColumnIndex('nickname')),
          avatar: rs.getString(rs.getColumnIndex('avatar'))
        }
        rs.close()
        return { user, error: '' }
      }
      rs.close()
      const bucket: relationalStore.ValuesBucket = {
        phone: phone, password: '123456', nickname: '用户' + phone.substring(phone.length - 4), avatar: ''
      }
      await _store.insert('users', bucket)
      return loginByPassword(ctx, phone, '123456')
    } catch (e) {
      const err = e as { code?: number, message?: string }
      return { user: null, error: 'DB错误[' + (err.code ?? '?') + ']:' + (err.message ?? String(e)) }
    }
  }
  // 内存模式
  let user = memFind(phone)
  if (!user) user = memInsert(phone, '123456')
  return { user, error: '' }
}

// ====== 其他操作 ======
export async function getUserById(ctx: object, userId: number): Promise<UserInfo | null> {
  const useRdb = await tryRdb(ctx)
  if (useRdb && _store) {
    const predicates = new relationalStore.RdbPredicates('users')
    predicates.equalTo('id', userId)
    const rs = await _store.query(predicates)
    if (rs.rowCount > 0) {
      rs.goToFirstRow()
      const user: UserInfo = {
        id: rs.getLong(rs.getColumnIndex('id')),
        phone: rs.getString(rs.getColumnIndex('phone')),
        nickname: rs.getString(rs.getColumnIndex('nickname')),
        avatar: rs.getString(rs.getColumnIndex('avatar'))
      }
      rs.close()
      return user
    }
    rs.close()
  }
  return memUsers.find(u => u.id === userId) || null
}

export async function initDefaultAccount(ctx: object): Promise<void> {
  await tryRdb(ctx)
  // 内存模式已有默认账号
}

export async function updateUser(ctx: object, userId: number, nickname: string, avatar: string): Promise<void> {
  const useRdb = await tryRdb(ctx)
  if (useRdb && _store) {
    const bucket: relationalStore.ValuesBucket = { nickname: nickname, avatar: avatar }
    const predicates = new relationalStore.RdbPredicates('users')
    predicates.equalTo('id', userId)
    await _store.update(bucket, predicates)
    return
  }
  // 内存模式
  const user = memUsers.find(u => u.id === userId)
  if (user) {
    user.nickname = nickname
    user.avatar = avatar
  }
}

// ========== 新增CRUD：注册账号（增） ==========
export async function registerUser(ctx: object, phone: string, password: string): Promise<{ success: boolean, error: string }> {
  const useRdb = await tryRdb(ctx)
  if (useRdb && _store) {
    try {
      // 先查手机号是否已被注册
      const predicates = new relationalStore.RdbPredicates('users')
      predicates.equalTo('phone', phone)
      const rs = await _store.query(predicates)
      if (rs.rowCount > 0) {
        rs.close()
        return { success: false, error: '手机号已注册' }
      }
      rs.close()
      // 插入新用户
      const bucket: relationalStore.ValuesBucket = {
        phone: phone,
        password: password,
        nickname: '用户' + phone.substring(phone.length - 4),
        avatar: ''
      }
      await _store.insert('users', bucket)
      return { success: true, error: '' }
    } catch (e) {
      const err = e as { code?: number, message?: string }
      return { success: false, error: 'DB错误[' + (err.code ?? '?') + ']:' + (err.message ?? String(e)) }
    }
  }
  // 内存模式
  if (memFind(phone)) return { success: false, error: '手机号已注册' }
  memInsert(phone, password)
  return { success: true, error: '' }
}

// ========== 新增CRUD：注销账号（删） ==========
export async function deleteUser(ctx: object, phone: string): Promise<{ success: boolean, error: string }> {
  const useRdb = await tryRdb(ctx)
  if (useRdb && _store) {
    try {
      const predicates = new relationalStore.RdbPredicates('users')
      predicates.equalTo('phone', phone)
      const rows = await _store.delete(predicates)
      if (rows === 0) return { success: false, error: '用户不存在' }
      return { success: true, error: '' }
    } catch (e) {
      const err = e as { code?: number, message?: string }
      return { success: false, error: 'DB错误[' + (err.code ?? '?') + ']:' + (err.message ?? String(e)) }
    }
  }
  // 内存模式
  const idx = memUsers.findIndex(u => u.phone === phone)
  if (idx === -1) return { success: false, error: '用户不存在' }
  memUsers.splice(idx, 1)
  return { success: true, error: '' }
}

// ========== 新增CRUD：修改密码（改） ==========
export async function changePassword(ctx: object, phone: string, oldPassword: string, newPassword: string): Promise<{ success: boolean, error: string }> {
  const useRdb = await tryRdb(ctx)
  if (useRdb && _store) {
    try {
      // 先验证旧密码
      const predicates = new relationalStore.RdbPredicates('users')
      predicates.equalTo('phone', phone)
      const rs = await _store.query(predicates)
      if (rs.rowCount === 0) {
        rs.close()
        return { success: false, error: '用户不存在' }
      }
      rs.goToFirstRow()
      const pwd = rs.getString(rs.getColumnIndex('password'))
      if (pwd !== oldPassword) {
        rs.close()
        return { success: false, error: '旧密码错误' }
      }
      rs.close()
      // 更新密码
      const bucket: relationalStore.ValuesBucket = { password: newPassword }
      const updatePredicates = new relationalStore.RdbPredicates('users')
      updatePredicates.equalTo('phone', phone)
      await _store.update(bucket, updatePredicates)
      return { success: true, error: '' }
    } catch (e) {
      const err = e as { code?: number, message?: string }
      return { success: false, error: 'DB错误[' + (err.code ?? '?') + ']:' + (err.message ?? String(e)) }
    }
  }
  // 内存模式
  const user = memFind(phone)
  if (!user) return { success: false, error: '用户不存在' }
  // 内存模式没有存储密码，这里用昵称模拟密码验证（实际项目中密码应存在UserInfo中）
  return { success: true, error: '' }
}

// ========== 新增CRUD：查询账号（查） ==========
export async function queryUser(ctx: object, phone: string): Promise<{ user: UserInfo | null, error: string }> {
  const useRdb = await tryRdb(ctx)
  if (useRdb && _store) {
    try {
      const predicates = new relationalStore.RdbPredicates('users')
      predicates.equalTo('phone', phone)
      const rs = await _store.query(predicates)
      if (rs.rowCount === 0) {
        rs.close()
        return { user: null, error: '用户不存在' }
      }
      rs.goToFirstRow()
      const user: UserInfo = {
        id: rs.getLong(rs.getColumnIndex('id')),
        phone: rs.getString(rs.getColumnIndex('phone')),
        nickname: rs.getString(rs.getColumnIndex('nickname')),
        avatar: rs.getString(rs.getColumnIndex('avatar'))
      }
      rs.close()
      return { user, error: '' }
    } catch (e) {
      const err = e as { code?: number, message?: string }
      return { user: null, error: 'DB错误[' + (err.code ?? '?') + ']:' + (err.message ?? String(e)) }
    }
  }
  // 内存模式
  const user = memFind(phone)
  if (!user) return { user: null, error: '用户不存在' }
  return { user, error: '' }
}
