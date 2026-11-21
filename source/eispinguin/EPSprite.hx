package eispinguin;

import collision.TerrainPhysics;
import flixel.FlxSprite;

class EPSprite extends FlxSprite
{
    // Physics
    public var physics:TerrainPhysics;

    // Velocities
    var velocityX:Float = 0;
    var velocityY:Float = 0;

    // Other things
    public var onGround:Bool = false;
    public var touchingWall:Bool = false;
    public var hittingCeiling:Bool = false;
    public var walkingIntoWall:Bool = false;

    public function new(x:Float, y:Float, physics:TerrainPhysics)
    {
        super(x, y);

        this.physics = physics;

        velocity.set(0, 0);
        acceleration.set(0, 0);
        drag.set(0, 0);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        
        velocity.set(0, 0);
    }

    public function getCenterX():Float
    {
        return x + width * 0.5;
    }

    public function getCenterY():Float
    {
        return y + height * 0.5;
    }

    public function getRight():Float
    {
        return x + width;
    }

    public function getBottom():Float
    {
        return y + height;
    }

    // Acceleration and deceleration
    public function approach(current:Float, target:Float, amount:Float):Float
    {
        if (current < target)
        {
            return Math.min(current + amount, target);
        }

        if (current > target)
        {
            return Math.max(current - amount, target);
        }

        return target;
    }

    // Just so the animation doesn't restart without a reason
    public function playAnimation(animation:String, force:Bool = false)
    {
        if (force)
        {
            this.animation.play(animation, true);
            return;
        }

        if (this.animation.name != animation)
        {
            this.animation.play(animation);
        }
    }
}