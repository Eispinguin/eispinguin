package objects;

import characters.Player;
import flixel.FlxG;
import flixel.FlxSprite;
import states.MainMenuState;
import states.PlayState;

class Goal extends FlxSprite
{
    public function new(x:Float, y:Float)
    {
        super(x, y);

        loadGraphic("assets/images/objects/portal.png");

        setSize(70, 163);
        offset.set(33, 0);
    }

    public function reach(eispi:Player)
    {
        if (solid)
        {
            solid = false;
            Global.currentLevel += 1;
        }

        if (Global.currentLevel >= Global.levels.length)
        {
            FlxG.switchState(MainMenuState.new);
        }
        else
        {
            FlxG.switchState(() -> new PlayState());
        }
    }
}