# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# 階級データの作成
weight_classes_data = [
  { japanese_name: "フライ級", english_name: "Flyweight" },
  { japanese_name: "バンタム級", english_name: "Bantamweight" },
  { japanese_name: "フェザー級", english_name: "Featherweight" },
  { japanese_name: "ライト級", english_name: "Lightweight" },
  { japanese_name: "ウェルター級", english_name: "Welterweight" },
  { japanese_name: "ミドル級", english_name: "Middleweight" },
  { japanese_name: "ライトヘビー級", english_name: "Light Heavyweight" },
  { japanese_name: "ヘビー級", english_name: "Heavyweight" }
]

weight_classes_data.each do |data|
  WeightClass.find_or_create_by!(japanese_name: data[:japanese_name]) do |weight_class|
    weight_class.english_name = data[:english_name]
  end
end

puts "階級データを#{WeightClass.count}件作成しました"

# 選手データの作成（サンプル）
fighters_data = [
  {
    full_name: "朝倉未来",
    full_name_hiragana: "あさくらみくる",
    ring_name: "路上の伝説",
    ring_name_hiragana: "ろじょうのでんせつ",
    weight_classes: ["フェザー級", "ライト級"]
  },
  {
    full_name: "朝倉海",
    full_name_hiragana: "あさくらかい",
    weight_classes: ["バンタム級"]
  },
  {
    full_name: "堀口恭司",
    full_name_hiragana: "ほりぐちきょうじ",
    ring_name: "GUCHI",
    ring_name_hiragana: "ぐち",
    weight_classes: ["フライ級", "バンタム級"]
  },
  {
    full_name: "扇久保博正",
    full_name_hiragana: "おうぎくぼひろまさ",
    weight_classes: ["バンタム級", "フェザー級"]
  },
  {
    full_name: "矢地祐介",
    full_name_hiragana: "やじゆうすけ",
    weight_classes: ["ライト級"]
  },
  {
    full_name: "斎藤裕",
    full_name_hiragana: "さいとうゆたか",
    ring_name: "NIGHT WOLF",
    ring_name_hiragana: "ないとうるふ",
    weight_classes: ["ウェルター級"]
  },
  {
    full_name: "摩嶋一整",
    full_name_hiragana: "まじまかずまさ",
    weight_classes: ["ライト級", "ウェルター級"]
  },
  {
    full_name: "砂辺光久",
    full_name_hiragana: "すなべみつひさ",
    weight_classes: ["ライト級"]
  },
  {
    full_name: "大雅",
    full_name_hiragana: "たいが",
    weight_classes: ["ヘビー級"]
  },
  {
    full_name: "武尊",
    full_name_hiragana: "たける",
    weight_classes: ["フェザー級"]
  }
]

fighters_data.each do |data|
  fighter = Fighter.find_or_create_by!(full_name: data[:full_name]) do |f|
    f.full_name_hiragana = data[:full_name_hiragana]
    f.ring_name = data[:ring_name]
    f.ring_name_hiragana = data[:ring_name_hiragana]
    f.is_active = true
  end
  
  # 階級の関連付け
  data[:weight_classes].each do |weight_class_name|
    weight_class = WeightClass.find_by(japanese_name: weight_class_name)
    if weight_class
      FighterWeightClass.find_or_create_by!(
        fighter: fighter,
        weight_class: weight_class
      )
    end
  end
end

puts "選手データを#{Fighter.count}件作成しました"
puts "選手と階級の関連付けを#{FighterWeightClass.count}件作成しました"
