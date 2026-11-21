package;

import lime.utils.Assets;
import states.PlayState;

class Global
{
    public static var PS:PlayState;

    public static var levels:Array<String>;
    public static var currentLevel = 0;

    public static function loadLevels()
    {
        levels = Assets.getText("assets/data/levels.txt").split("\n").map(StringTools.trim).filter(function(l) return l != "");
    }
}