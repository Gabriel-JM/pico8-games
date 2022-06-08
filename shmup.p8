pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
-- init

function _init()
 upd=update_start
 drw=draw_start
 
 blinkt=1
end

function _draw()
	drw()
end

function _update()
	blinkt+=1
	upd()
end

function startgame()
	upd=update_game
	drw=draw_game
	ship={
		x=64,
		y=64,
		sx=0,
		sy=0,
		spr=2
	}
	
	lives=4
		
	flame_spr=5
	
	bullets={}
	
	muzzle=0
	
	stars={}
	for i=1,100 do
		add(stars,{
			x=flr(rnd(128)),
			y=flr(rnd(128)),
			spd=rnd(1.5)+0.5
		})
	end
	
	enemies={}
	
	for i=1,10 do
		add(enemies,{
			x=rnd(110)+10,
			y=rnd(5)-(rnd(40)+40),
			spr=21
		})
	end
end
-->8
-- tools

function create_starfield()
	foreach(stars,function(s)
		pset(
			s.x,
			s.y,
			get_star_col(s.spd)
		)
	end)
end

function get_star_col(spd)
	if spd<1 then
		return 1
	end
	
	if spd<1.5 then
		return 13
	end

	return 6
end

function update_stars()
	foreach(stars,function(s)
		s.y+=s.spd
		
		if s.y>127 then
			s.y=-1
		end
	end)
end

function blink()
	local blink_colors=split"5,6,7,6,5"
	return blink_colors[
		flr((blinkt/7)%5+1)
	]
end

function has_collision(a,b)
	if (a.y>b.y+7) return false
	if (b.y>a.y+7) return false
	if (a.x>b.x+7) return false
	if (b.x>a.x+7) return false
	
	return true
end
-->8
-- update

function update_start()
	if btnp(4) or btnp(5) then
		startgame()
	end
end

function update_game()
	ship.sx,ship.sy,ship.spr=0,0,2

	if btn(⬅️) then
		ship.sx=-2
		ship.spr=1
	end
	if (btn(➡️)) then
		ship.sx=2
		ship.spr=3
	end
	if (btn(⬆️)) ship.sy=-2
	if (btn(⬇️)) ship.sy=2
	if btnp(🅾️) then
		add(bullets,{
			x=ship.x,
			y=ship.y-4,
			spr=16
		})
		sfx(0)
		muzzle=6
	end
	
	foreach(enemies,function(e)
		e.y+=1
		
		e.spr+=0.4
		if e.spr>=25 then
			e.spr=21
		end
		
		if e.y>128 then
			del(enemies,e)
		end
		
		if has_collision(e,ship) then
			lives-=1
			sfx(1)
			del(enemies,e)
		end
	end)
	
	ship.x+=ship.sx
	ship.y+=ship.sy
	
	ship.x=mid(0,ship.x,127-8)
	ship.y=mid(0,ship.y,127-8)
	
	foreach(bullets,function(b)
		b.y-=4
		
		foreach(enemies,function(e)
			if has_collision(e,b) then
				sfx(1)
				del(enemies,e)
				del(bullets,b)
			end
		end)
		
		if b.y<-4 then
			del(bullets,b)
		end
	end)
	
	flame_spr+=1
	
	if flame_spr>9 then
		flame_spr=5
	end
	
	muzzle=max(0,muzzle-1)
	
	update_stars()
	
	if lives<=0 then
		upd=update_start
		drw=draw_gameover
	end
end
-->8
-- draw

function draw_start()
	cls(1)
	print(
		"shoot them up!",
		36,
		40,
		7
	)
	print(
		"press any key to start",
		20,
		80,
		blink()
	)
end

function draw_game()
	cls()
	create_starfield()
	
	draw_sprite(ship)
	spr(flame_spr,ship.x,ship.y+8)
	
	draw_sprites(enemies)	
	draw_sprites(bullets)
	
	if muzzle>0 then
		circfill(
			ship.x+3,
			ship.y-2,
			muzzle,
			7
		)
	end
	
	for i=1,4 do
		spr(
			lives<i and 14 or 13,
			(i-1)*10,
			1
		)
	end
end

function draw_sprites(list)
	foreach(list,draw_sprite)
end

function draw_sprite(item)
	spr(item.spr,item.x,item.y)
end

function draw_gameover()
	cls(2)
	print(
		"game over!",
		46,
		40,
		7
	)
	print(
		"press any key to restart",
		20,
		80,
		blink()
	)
end
__gfx__
00000000000220000002200000022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000028820000288200002882000000000000077000000770000007700000c77c0000077000000000000000000000000000088008800880088000000000
007007000028820000288200002882000000000000c77c000007700000c77c000cccccc000c77c00000000000000000000000000888888888008800800000000
000770000028882002888820028882000000000000cccc00000cc00000cccc0000cccc0000cccc00000000000000000000000000888888888000000800000000
0007700002cc8820288cc8820288cc2000000000000cc000000cc000000cc00000000000000cc000000000000000000000000000088888800800008000000000
0070070002c68820288c688202886c200000000000000000000cc000000000000000000000000000000000000000000000000000008888000080080000000000
00000000025588200285582002885520000000000000000000000000000000000000000000000000000000000000000000000000000880000008800000000000
00000000002992000029920000299200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000330033003300330033003300330033000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000003bb33bb33bb33bb33bb33bb33bb33bb300000000000000000000000000000000000000000000000000000000
00099000000000000000000000000000000000003bbbbbb33bbbbbb33bbbbbb33bbbbbb300000000000000000000000000000000000000000000000000000000
009aa900000000000000000000000000000000003b7717b33b7717b33b7717b33b7717b300000000000000000000000000000000000000000000000000000000
009aa900000000000000000000000000000000000b7117b00b7117b00b7117b00b7117b000000000000000000000000000000000000000000000000000000000
00099000000000000000000000000000000000000037730000377300003773000037730000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000303303003033030030330300303303000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000300003033000033300000030330033000000000000000000000000000000000000000000000000000000000
__sfx__
0001000035540305402855024550205501c550185501555011550105500e5500c5500954007530055200152000510000000000000000000000000000000000000000000000000000000000000000000000000000
00010000316502d64029640226401b650176501464011640106300f6200d6200b6200962007620076100561004610036100261000010000000000000000000000000000000000000000000000000000000000000
