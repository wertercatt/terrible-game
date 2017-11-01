#-------------------------------------------------------------------
# Ellye's Combat Interface
# A Combat UI script made by Ellye.
# This is a free script for non-commercial use, provided "as is", no warranties.
#-------------------------------------------------------------------

#--------------------------------------------------------------------------
# * Changes the Maximum number of battle party members to 6
#--------------------------------------------------------------------------
class Game_Party
  def max_battle_members
    return 6
  end
end

class Spriteset_Battle
  def create_actors
     @actor_sprites = Array.new(6) { Sprite_Battler.new(@viewport1) }
  end
end

#--------------------------------------------------------------------------
# * Uses charset sprites as Actor battlers sprites
#--------------------------------------------------------------------------
class Game_Actor
  attr_accessor :screen_x
  attr_accessor :screen_y                 
  attr_accessor :screen_z
  
  alias :old_initialize :initialize
  def initialize(actor_id)
    old_initialize(actor_id)
    @screen_x = 0
    @screen_y = 0
  end
  
  def screen_z
    return 100
  end
  
  def use_sprite?
    return true
  end
  
  alias :old_on_battle_start :on_battle_start
  def on_battle_start
    old_on_battle_start
    @screen_x = 180 + (92 * (self.index % 3))
    self.index < 3 ? @screen_y = 320 : @screen_y = 384
  end
  
end

class Sprite_Battler
  def update_bitmap
    if @battler.battler_name == "" && @battler.character_name != ""
      @battler.character_index < 4 ? rect_y = 96 : rect_y = 224 #Selecting correct row for the sprite (Standard size)
      rect_x =  32 + (96*(@battler.character_index % 4)) #Selecting correct colunm  for the sprite (Standard size)
      new_bitmap_cs = Cache.character(@battler.character_name) #Load charset
      new_bitmap = Bitmap.new(32, 32) #Make empty, standard character sized, bitmap
      new_bitmap.blt(0, 0, new_bitmap_cs, Rect.new(rect_x, rect_y, 32, 32))  #Copies the sprite from the charset to the new bitmap
    else
      new_bitmap = Cache.battler(@battler.battler_name, @battler.battler_hue)
    end
    
    if bitmap != new_bitmap
      self.bitmap = new_bitmap
      init_visibility
    end
    
  end
  
  #--------------------------------------------------------------------------
  # * Changing the duration of some effects, and adding a new :pounce effect for physical attacks
  #--------------------------------------------------------------------------
  def start_effect(effect_type)
    @effect_type = effect_type
    case @effect_type
    when :appear
      @effect_duration = 32
      @battler_visible = true
    when :disappear
      @effect_duration = 64
      @battler_visible = false
    when :pounce
      @effect_duration = 32
      @battler_visible = true
    when :whiten
      @effect_duration = 32
      @battler_visible = true
    when :blink
      @effect_duration = 40
      @battler_visible = true
    when :collapse
      @effect_duration = 48
      @battler_visible = false
    when :boss_collapse
      @effect_duration = bitmap.height
      @battler_visible = false
    when :instant_collapse
      @effect_duration = 16
      @battler_visible = false
    end
    revert_to_normal
  end
#--------------------------------------------------------------------------
# * Updating the Pounce Effect
#--------------------------------------------------------------------------
    def update_effect
      if @effect_duration > 0
        @effect_duration -= 1
        case @effect_type
        when :pounce
          update_pounce
        when :whiten
          update_whiten
        when :blink
          update_blink
        when :appear
          update_appear
        when :disappear
          update_disappear
        when :collapse
          update_collapse
        when :boss_collapse
          update_boss_collapse
        when :instant_collapse
          update_instant_collapse
        end
        @effect_type = nil if @effect_duration == 0
      end
    end
  
  def update_pounce
    @effect_duration > 16 ? self.oy += 32 - @effect_duration : self.oy += @effect_duration
  end
  
  alias :old_revert_to_normal :revert_to_normal
  def revert_to_normal
    old_revert_to_normal
    self.oy = bitmap.height
  end
  
end

#--------------------------------------------------------------------------
# *  Battle Scene layout
#--------------------------------------------------------------------------
class Scene_Battle
  alias :old_create_status_window :create_status_window
  alias :old_create_info_viewport :create_info_viewport
  
  def create_status_window
    old_create_status_window
    @status_window.x = 137
    @status_window.set_handler(:ok,     method(:on_actor_ok)) #We will use the status window for party-targetting
    @status_window.set_handler(:cancel, method(:on_actor_cancel)) #We will use the status window for party-targetting
  end
  
  def create_info_viewport
    old_create_info_viewport
    @info_viewport.ox = 0
  end
  
  def move_info_viewport(ox)
    current_ox = @info_viewport.ox #don't move anymore
  end
    
  alias :old_create_actor_command_window :create_actor_command_window
  def create_actor_command_window
    old_create_actor_command_window
    @actor_command_window.x = Graphics.width - @actor_command_window.width
  end
  
  def select_actor_selection
    @status_window.refresh
    @status_window.activate #We will use the status window for party-targetting
  end
  
  def on_actor_ok
    BattleManager.actor.input.target_index = @status_window.index #We will use the status window for party-targetting
    @actor_window.hide
    @skill_window.hide
    @item_window.hide
    next_command
  end
  
  def abs_wait_short
    abs_wait(20)
  end

  def execute_action
    if @subject.actor? 
      @subject.sprite_effect_type = :pounce #changed to the custom pounce effect
    else
      @subject.sprite_effect_type = :whiten #enemies still look better with whiten
    end
    use_item
    abs_wait_short #Slowing things down a bit
    @log_window.wait_and_clear
  end

end

 #--------------------------------------------------------------------------
 # *  Battle Status Window layout
 #--------------------------------------------------------------------------
class Window_BattleStatus
  def initialize
      super(0, 0, window_width, window_height)
      refresh
      self.openness = 0
      self.opacity = 0
  end
  def window_width
    270
  end
  def window_height
    144
  end
  def col_max
    return 3
  end
  def spacing
    return 6
  end
  def standard_padding
    return 0
  end
  def item_height
    return 48
  end
  def item_rect(index)
      rect = Rect.new
      rect.width = item_width
      rect.height = item_height
      rect.x = index % col_max * (item_width + spacing)
      rect.y = 8 + (index / col_max * (item_height + 16))
      rect
  end
  
  def draw_vertical_actor_icons(actor, x, y, height = 24)
    icons = (actor.state_icons + actor.buff_icons)[0, height / 24]
    icons.each_with_index {|n, i| draw_icon(n, x, y + 24*i) }
  end
  
  def draw_item(index)
    actor = $game_party.battle_members[index]
    rect = item_rect(index)
    draw_actor_hp(actor, rect.x, rect.y+32, rect.width)
    draw_vertical_actor_icons(actor, rect.x, rect.y)
    if $data_system.opt_display_tp
      draw_actor_mp(actor, rect.x, rect.y+48, (rect.width/2)-1)
      draw_actor_tp(actor, rect.x+(rect.width/2)+2, rect.y+48, (rect.width/2)-1)
    else
      draw_actor_mp(actor, rect.x, rect.y+48, rect.width)
    end
  end
end

#--------------------------------------------------------------------------
# *  Battle Log - slowing it down a bit
#--------------------------------------------------------------------------
class Window_BattleLog
  
  def display_action_results(target, item)
    if target.result.used
      last_line_number = line_number
      display_critical(target, item)
      display_damage(target, item)
      display_affected_status(target, item)
      display_failure(target, item)
      wait if line_number > last_line_number
    end
  end
  
  def wait_and_clear
    wait while @num_wait < 4 if line_number > 0
    clear
  end
  
end