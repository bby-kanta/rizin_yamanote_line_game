class FixFighterRingNameHiraganaColumn < ActiveRecord::Migration[8.0]
  def change
    rename_column :fighters, :ring_name_hiraganam, :ring_name_hiragana
  end
end
