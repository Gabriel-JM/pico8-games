pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
-- init

function _init()
 upd=update_start
 drw=draw_start
 
 t=0
 blinkt=1
end

function _draw()
	drw()
end

function _update()
	t+=1
	blinkt+=1
	upd()
end

function startgame()
	upd=update_game
 drw=draw_game
	t=0
	
	ship={
		x=64,
		y=64,
		sx=0,
		sy=0,
		spr=2
	}
	
	lives=4
	invul=0
	muzzle=0
	
	flame_spr=5
	
	bullets={}
	bullet_timer=0
	
	stars={}
	for i=1,100 do
		add(stars,{
			x=flr(rnd(128)),
			y=flr(rnd(128)),
			spd=rnd(1.5)+0.5
		})
	end
	
	enemies={}
	spawn_enemy()
	
	explosions={}
	
	shock_waves={}
	
	particles={}
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

function spawn_enemy()
	add(enemies,{
		x=rnd(110)+10,
		y=-(rnd(10)+10),
		spr=21,
		hp=5,
		flash=0
	})
end

function explode(x,y,is_blue)
	add(particles,{
		x=x,
		y=y,
		sx=0,
		sy=0,
		age=0,
		size=10,
		max_age=0,
		blue=is_blue
	})

	for i=1,30 do
		add(particles,{
			x=x,
			y=y,
			sx=(rnd()-0.5)*6,
			sy=(rnd()-0.5)*6,
			age=rnd(2),
			size=1+rnd(4),
			max_age=10+rnd(10),
			blue=is_blue
		})
	end
	
	for i=1,20 do
		add(particles,{
			x=x,
			y=y,
			sx=(rnd()-0.5)*10,
			sy=(rnd()-0.5)*10,
			age=rnd(2),
			size=1+rnd(4),
			max_age=10+rnd(10),
			spark=true
		})
	end
	
	big_shwave(x,y)
end

function small_sparks(x,y)
	add(particles,{
		x=x,
		y=y,
		sx=(rnd()-0.5)*8,
		sy=(rnd()-1)*3,
		age=rnd(2),
		size=1+rnd(4),
		max_age=10+rnd(10),
		spark=true
	})
end

red_age_colors={
	{15,5},
	{12,2},
	{10,8},
	{7,9},
	{5,10},
	{0,7}
}

blue_age_colors={
	{12,1},
	{10,13},
	{7,12},
	{5,6},
	{0,7}
}
function age_particle(
	age,
	is_blue
)
	local age_colors=is_blue
		and blue_age_colors
		or red_age_colors
	
	for
		age_col in all(age_colors)
	do
		if age>age_col[1] then
			return age_col[2]
		end
	end
end

function small_shwave(x,y)
	add(shock_waves,{
		x=x,
		y=y,
		color=9,
		r=3,
		speed=1,
		target_r=6
	})
end

function big_shwave(x,y)
	add(shock_waves,{
		x=x,
		y=y,
		color=7,
		r=3,
		speed=3.5,
		target_r=25
	})
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
	if btn(🅾️) then
		if bullet_timer<=0 then
			add(bullets,{
				x=ship.x,
				y=ship.y-4,
				spr=16
			})
			sfx(0)
			muzzle=6
			bullet_timer=4
		end
	end
	
	bullet_timer-=1
	
	foreach(bullets,function(b)
		b.y-=4
		
		foreach(enemies,function(e)
			if has_collision(e,b) then
				del(bullets,b)
				e.hp-=1
				sfx(3)
				e.flash=2
				small_sparks(b.x+4,b.y+4)
				small_shwave(b.x+4,b.y+4)
				
				if e.hp<=0 then
					sfx(1)
					del(enemies,e)
					spawn_enemy()
					explode(e.x+4,e.y+4)
				end
			end
		end)
		
		if b.y<-4 then
			del(bullets,b)
		end
	end)
	
	invul=max(0,invul-1)
	
	foreach(enemies,function(e)
		e.y+=1
		
		e.spr+=0.4
		if e.spr>=25 then
			e.spr=21
		end
		
		if e.y>128 then
			del(enemies,e)
			spawn_enemy()
		end
		
		if
			invul==0
		 and has_collision(e,ship)
		then
			explode(
				ship.x+4,
				ship.y+4,
				true
			)
			lives-=1
			invul=60
			sfx(1)
		end
	end)
	
	ship.x+=ship.sx
	ship.y+=ship.sy
	
	ship.x=mid(0,ship.x,127-8)
	ship.y=mid(0,ship.y,127-8)
	
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
	
	if
		invul<=0
		or sin(t/5)<0.1
	then
		draw_sprite(ship)
		spr(flame_spr,ship.x,ship.y+8)
	end
	
	foreach(enemies,function(e)
		if e.flash>0 then
			e.flash-=1
			for i=1,15 do
				pal(i,7)
			end
		end
		
		draw_sprite(e)
		pal()
	end)

	draw_sprites(bullets)
	
	if muzzle>0 then
		circfill(
			ship.x+3,
			ship.y-2,
			muzzle,
			7
		)
	end
	
	foreach(shock_waves,function(s)
		circ(s.x,s.y,s.r,s.color)
		s.r+=s.speed
		
		if s.r>s.target_r then
			del(shock_waves,s)
		end
	end)
	
	foreach(particles,function(p)
		local p_color=age_particle(
			p.age,p.blue
		)
		
		if p.spark then
			pset(p.x,p.y,7)
		else
			circfill(
				p.x,
				p.y,
				p.size,
				p_color
			)
		end
		
		p.x+=p.sx
		p.y+=p.sy
		p.age+=1
		
		p.sx*=0.85
		p.sy*=0.85
		
		if p.age>p.max_age then
			p.size-=0.5
		end
		
		if p.size<0 then
			del(particles,p)
		end
	end)
	
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
00099000000000000000000000000000000000003bb33bb33bb33bb33bb33bb33bb33bb300000000000000000000000000000000000000000000000000000000
009aa900000000000000000000000000000000003bbbbbb33bbbbbb33bbbbbb33bbbbbb300000000000000000000000000000000000000000000000000000000
09a77a90000000000000000000000000000000003b7717b33b7717b33b7717b33b7717b300000000000000000000000000000000000000000000000000000000
09a77a90000000000000000000000000000000000b7117b00b7117b00b7117b00b7117b000000000000000000000000000000000000000000000000000000000
009aa900000000000000000000000000000000000037730000377300003773000037730000000000000000000000000000000000000000000000000000000000
00099000000000000000000000000000000000000303303003033030030330300303303000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000300003033000033300000030330033000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000500000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000880088999900000055505555555005005055550000555000500050055550050000000000000000000000000000000000000000000000000
00000000990000000800999999990800500059998885550050005588555555500000000055050500000000000000000000000000000000000000000000000000
000000aaaaa000000009999aaa99980005588a989999855050588585558885000555005050000050000000000000000000000000000000000000000000000000
0090aaaaaaaa090000999aaaaaaa90000888a99999a9855000555595555985000050555000005050000000000000000000000000000000000000000000000000
0000aa77777aa0000999aaaaaaaa99000899999aa9aa850000555555895985050500050000000000000000000000000000000000000000000000000000000000
000aa777777aa0000999aa777aaa99000899aaaaaa99950008505958895595000000000000055000000000000000000000000000000000000000000000000000
000aa7777777a00009aaaa7777aaa9000589aa777a99a95050005555559598000000550000555000000000000000000000000000000000000000000000000000
0009aa77777aa000099aaa777aaa990055899aa7aaa9990005555555559599050005550005555500000000000000000000000000000000000000000000000000
000aaa77777aa9000999aaa77aaa990055889aaaaaa9850005589589955585000000555005550000000000000000000000000000000000000000000000000000
0000aaaaaaaaa00008999aaaaaaa9980058899999aa9850000889588558585000000055500000000000000000000000000000000000000000000000000000000
0000000aaaaa0000008999aaaaa990000558889999a9850005588599988585500500055505550500000000000000000000000000000000000000000000000000
00000000000000900809999999999000005559aa9998855005555555855885550050555005500550000000000000000000000000000000000000000000000000
00000900000900000088009999908800500055888885550050005588558550050500500005005555000000000000000000000000000000000000000000000000
00000000000000000000000000008000055005555550050055000555555000550550000000000050000000000000000000000000000000000000000000000000
00000000000000000000000000000000050000050000005005055550000000500500000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000035540305402855024550205501c550185501555011550105500e5500c5500954007530055200152000510000000000000000000000000000000000000000000000000000000000000000000000000000
00010000316502d64029640226401b650176501464011640106300f6200d6200b6200962007620076100561004610036100261000010000000000000000000000000000000000000000000000000000000000000
00010000256301d620184001b40022400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000256301d620184001b40022400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
