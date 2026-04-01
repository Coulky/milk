# Milk - 猫咪牛奶大战老鼠

一个使用 Godot 4 + GDScript 开发的猫咪牛奶大战老鼠游戏。

## 项目结构

```
milk/
├── configs/              # 配置文件目录
│   ├── characters.json   # 角色配置
│   ├── enemies.json      # 敌人配置
│   ├── weapons.json      # 武器和被动道具配置
│   └── game_settings.json # 游戏设置
├── scripts/              # 脚本目录
│   ├── managers/         # 管理器
│   │   ├── config_manager.gd   # 配置管理器
│   │   ├── game_manager.gd     # 游戏管理器
│   │   └── enemy_spawner.gd    # 敌人生成器
│   ├── entities/         # 实体
│   │   ├── player/       # 玩家
│   │   ├── enemies/      # 敌人
│   │   ├── weapons/      # 武器
│   │   └── pickups/      # 拾取物
│   └── ui/               # UI
├── scenes/               # 场景目录
│   ├── entities/         # 实体场景
│   ├── ui/               # UI 场景
│   └── main.tscn         # 主场景
└── project.godot         # Godot 项目文件
```

## 快速开始

1. 使用 Godot 4.2+ 打开项目
2. 运行主场景（F5）
3. 使用 WASD 或方向键移动
4. 自动攻击周围的敌人
5. 收集经验宝石升级
6. 选择升级强化角色

## 配置系统

### 添加新角色

编辑 `configs/characters.json`:

```json
{
  "id": "archer",
  "name": "弓箭手",
  "description": "远程攻击角色",
  "symbol": "A",
  "symbol_color": "#ffff00",
  "model_path": "",
  "max_health": 80,
  "speed": 220,
  "attack": 15,
  "defense": 3,
  "starting_weapons": ["fire_ring"],
  "unlock_condition": {
    "type": "kill_enemies",
    "value": 500
  }
}
```

### 添加新敌人

编辑 `configs/enemies.json`:

```json
{
  "id": "dragon",
  "name": "龙",
  "symbol": "D",
  "symbol_color": "#ff4400",
  "model_path": "",
  "max_health": 200,
  "speed": 60,
  "damage": 30,
  "experience": 50,
  "spawn_weight": 1,
  "min_wave": 5
}
```

### 添加新武器

编辑 `configs/weapons.json`:

```json
{
  "id": "ice_bolt",
  "name": "冰霜箭",
  "description": "发射减速敌人的冰箭",
  "type": "projectile",
  "symbol": "I",
  "symbol_color": "#00ffff",
  "model_path": "",
  "damage": 12,
  "attack_speed": 1.2,
  "range": 350,
  "projectile_count": 2,
  "projectile_speed": 450,
  "piercing": 2,
  "special_effect": "slow",
  "evolution": {
    "required_item": "spellbook",
    "evolves_to": "blizzard"
  }
}
```

### 添加被动道具

编辑 `configs/weapons.json` 的 `passive_items` 部分:

```json
{
  "id": "wing",
  "name": "翅膀",
  "description": "增加移动速度",
  "symbol": "W",
  "symbol_color": "#ffffff",
  "model_path": "",
  "effects": {
    "speed": 0.1
  },
  "max_level": 5
}
```

## 替换模型

当前使用符号（symbol）代替模型。要替换为真实模型：

1. 准备模型文件（如 `.glb`, `.gltf` 或 `.png`）
2. 将模型放入项目目录（如 `assets/models/`）
3. 在配置文件中设置 `model_path`:

```json
{
  "id": "warrior",
  "model_path": "res://assets/models/warrior.glb",
  ...
}
```

4. 修改对应的脚本加载模型而非符号

## 游戏机制

### 武器类型

- **melee**: 近战武器，攻击周围敌人
- **projectile**: 发射弹幕，可选追踪
- **area**: 区域攻击，影响范围内所有敌人
- **instant**: 瞬时攻击，随机攻击屏幕上的敌人

### 升级系统

- 击杀敌人获得经验宝石
- 收集足够经验后升级
- 每次升级可选择新武器或被动道具
- 武器可通过被动道具进化

### 波次系统

游戏按时间分波：
- 第 0 分钟：僵尸、蝙蝠
- 第 1 分钟：增加骷髅
- 第 3 分钟：增加幽灵
- 第 5 分钟：增加恶魔

可在 `configs/game_settings.json` 中调整。

## 自定义扩展

### 添加新的武器类型

1. 在 `scripts/entities/weapons/weapon_base.gd` 中添加新的攻击逻辑
2. 在 `perform_attack()` 函数中添加新的 case
3. 在配置文件中设置 `type` 字段

### 添加新的敌人 AI

1. 创建新的敌人脚本继承 `enemy.gd`
2. 重写 `_physics_process()` 或 `move_towards_target()`
3. 在配置中指定自定义脚本

## 控制说明

- **WASD / 方向键**: 移动
- **ESC**: 暂停/继续
- **R**: 游戏结束后重新开始

## 开发计划

- [ ] 添加更多武器类型
- [ ] 添加 Boss 战
- [ ] 添加成就系统
- [ ] 添加角色解锁系统
- [ ] 添加音效和音乐
- [ ] 添加粒子效果
- [ ] 添加地图障碍物
- [ ] 数值调整

## 需要素材

- [ ] 首页界面 1920 * 1080
- [ ] 角色图片 角色面朝方向向左 64 * 64  

## 许可证

MIT License
