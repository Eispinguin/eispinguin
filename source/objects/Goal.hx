package objects;

import characters.Player;
import editor.LevelEditorState;
import flixel.FlxG;
import flixel.FlxSprite;
import states.MainMenuState;
import states.PlayState;

class Goal extends FlxSprite
{
    public function new(x:Float, y:Float)
    {
        super(x, y);

        loadGraphic("assets/images/objects/goal/portal-snow.png");

        setSize(70, 163);
        offset.set(33, 0);
    }

    public function reach()
    {
        if (!solid)
        {
            return;
        }

        solid = false;

        if (Global.PS.editorPlaytest)
        {
            FlxG.switchState(() -> new LevelEditorState(Global.PS.editorLevelPath, Global.PS.editorSavePath, Global.PS.editorPlaytestJson, Global.PS.editorHistory, Global.PS.editorCurrentFilePath));
            return;
        }

        Global.currentLevel += 1;

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