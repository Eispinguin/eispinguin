package editor;

class EditorHistory
{
    var snapshots:Array<String> = [];
    var currentIndex:Int = -1;

    public var maxHistory:Int = 100;

    public function new()
    {
    }

    public function reset(json:String)
    {
        snapshots = [json];
        currentIndex = 0;
    }

    public function push(json:String)
    {
        if (currentIndex >= 0 && snapshots[currentIndex] == json)
        {
            return;
        }

        snapshots.splice(currentIndex + 1, snapshots.length - currentIndex - 1);

        snapshots.push(json);
        currentIndex += 1;

        if (snapshots.length > maxHistory)
        {
            snapshots.shift();
            currentIndex -= 1;
        }
    }

    public function undo():Null<String>
    {
        if (currentIndex <= 0)
        {
            return null;
        }

        currentIndex -= 1;

        return snapshots[currentIndex];
    }

    public function redo():Null<String>
    {
        if (currentIndex >= snapshots.length - 1)
        {
            return null;
        }

        currentIndex += 1;

        return snapshots[currentIndex];
    }

    public function canUndo():Bool
    {
        return currentIndex > 0;
    }

    public function canRedo():Bool
    {
        return currentIndex < snapshots.length - 1;
    }
}