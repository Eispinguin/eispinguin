//  Eispinguin
//  Copyright (C) 2026 AnatolyStev
//                2026 Vaesea <sophieballvaesea@proton.me>
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

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