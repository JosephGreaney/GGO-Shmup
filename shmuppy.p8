pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
t=0
damage=10

function btnr(key, rep)
  rep=60 - (rep or 1)
  -- change rep here so that it can always be divisible by the rep.
  return btn(key) and t%rep==0
end

function log(msg)
  log_msg=msg
end

function _init()
  shake=0
  boss = {
    spr=6,
    x=40,
    y=-20,
    h=1000,
    w=48,
    d=1,
    shoot=60,
    shootLen=0,
    box={x1=4,y1=0,x2=48,y2=44},
  }
  ship={
    spr=1,
    x=60,
    y=60,
    fireRate=50,
    h=3,
    imm=0,
    movespeed=1.3,
    box={x1=0,y1=0,x2=7,y2=7},
  }
  bullets={}
  enemies={}
  explosions={}
  stars={}

  for i=1,128 do
    add(stars,{
      x=rnd(128),
      y=rnd(128),
      s=rnd(2)+1
    })
  end

  start()
end

function start()
  _update60=update_game
  _draw=draw_game
end

--[[-----------------------------------------
  Game Over State Functions
-----------------------------------------]]--
function game_over()
  _update60=update_over
  _draw=draw_over
end

function update_over()

end

function draw_over()
  cls()
  print("game over", 50, 50, 4)
end

--[[-----------------------------------------
  Game Play State Functions
-----------------------------------------]]--
function update_game()
  screenshake()
  t=t+1
  if ship.imm > 0 then
    ship.imm -= 1
  end
  if (t%5==0) then
    ship.spr=t % 2 + 1
  end

   for st in all(stars) do
    st.y += st.s
    if st.y >= 128 then
      st.y=0
      st.x=rnd(128)
    end
  end

  for ex in all(explosions) do
    ex.t+=1
    if ex.t == 26 then
      del(explosions, ex)
    end
  end

  if #enemies <= 0 then
    -- respawn()
  end

  for b in all(bullets) do
    b.x+=b.dx
    b.y+=b.dy
    if out_of_bounds(b.x, b.y) then
      del(bullets, b)
    end

    for e in all(enemies) do
      if coll(b,e) then
        del(enemies,e)
        del(bullets,b)
        explode(e.x, e.y)
      end
    end

    if boss.h > 0 and coll(b, boss) then
      boss.h -= 10
      explode(b.x, b.y)
      del(bullets, b)
    end
  end

  if boss.h > 0 then
    boss.x = mid(0, boss.x + boss.d, 128-boss.w)
    if rnd(100) < 2 then
      boss.d *= -1
    end
    if rnd(10) < 2 then
      boss.shoot = 60
    end
  end

  if boss.shoot > 0 then
    boss.shoot -= 6
    boss.shootLen = min(boss.shootLen+6, 128)
    if boss.shoot == 0 then
      boss.shootLen = 0
    end
  end

  for e in all(enemies) do
    e.m_y += 0.5
    e.x=e.r*sin(e.d*t/100) + e.m_x
    e.y=e.r*cos(e.d*t/100) + e.m_y
    if coll(ship,e) and ship.imm == 0 then
      shake=3
      ship.imm=60
      ship.h -= 1
      if ship.h <= 0 then
        game_over()
      end
    end
    if e.y > 150 then
      del(enemies, e)
    end
  end
  local speed=ship.movespeed
  if btn(0) then ship.x=max(ship.x - speed, -4) end
  if btn(1) then ship.x=min(ship.x + speed, 124) end
  if btn(2) then ship.y=max(ship.y - speed, -4) end
  if btn(3) then ship.y=min(ship.y + speed, 124) end
  if btnr(4, ship.fireRate) then fire() end
  if btnp(5) then
    ship.movespeed += .1
  end
end

function draw_game()
  cls()
  pal()
  if log_msg then
    print(log_msg)
  end
  print(ship.movespeed)

  for st in all(stars) do
    pset(st.x,st.y,6)
    -- Extra stars if we need
    -- pset(st.x,st.y-1,6)
    -- pset(st.x,st.y-2,6)
    -- pset(st.x,st.y-3,6)
  end

  for b in all(bullets) do
    spr(b.sp, b.x, b.y)
  end
  if not (ship.imm > 0) or t%16 < 4 then
    spr(ship.spr, ship.x, ship.y)
  end

  for e in all(enemies) do
    spr(e.sp, e.x, e.y)
  end

  if boss.h > 0 then
    if boss.shoot > 0 then
      sspr(56,0,8,8,boss.x+8, boss.y+boss.w+boss.shootLen, boss.w-16, boss.shootLen)
    end
    sspr(48,0,8,8,boss.x,boss.y,boss.w,boss.w)
  end

  for ex in all(explosions) do
    circ(ex.x, ex.y, ex.t/2,8+ex.t%3)
  end

  for i=1,4 do
    if i<= ship.h then
      spr(33,80+6*i,3)
    else
      spr(34,80+6*i,3)
    end
  end
end

function respawn()
  local n=flr(rnd(9))+2
  for i=1,n do
    local d=-1
    if rnd(1)<0.5 then d=1 end
    add(enemies, {
      sp=17,
      m_x=i*16,
      m_y=-20-i*8,
      d=d,
      x=-32,
      y=-32,
      r=12,
      box={x1=2,y1=0,x2=5,y2=4},
    })
  end
end

function fire()
  local b={
    sp=3,
    x=ship.x,
    y=ship.y,
    dx=0,
    dy=-3,
    box={x1=5,y1=0,x2=7,y2=4},
  }
  add(bullets,b)
end

function explode(x,y)
  add(explosions, {x=x, y=y, t=0})
  shake=1
end

function coll(a,b)
  local box_a=abs_box(a)
  local box_b=abs_box(b)

  return not(box_a.x1 > box_b.x2 or
     box_a.y1 > box_b.y2 or
     box_b.x1 > box_a.x2 or
     box_b.y1 > box_a.y2)
end

function abs_box(s)
  local box={}
  box.x1=s.box.x1 + s.x
  box.x2=s.box.x2 + s.x
  box.y1=s.box.y1 + s.y
  box.y2=s.box.y2 + s.y
  return box
end

function out_of_bounds(x, y)
  return x < 0 or x > 128 or
         y < 0 or y > 128
end

function screenshake(intensity)
  intensity=intensity or 1
  local shakex=intensity - rnd(intensity*2)
  local shakey=intensity - rnd(intensity*2)
  shakex*=shake
  shakey*=shake
  shake=shake*0.8
  camera(shakex, shakey)
  if (shake<0.05) then shake=0 end
end
__gfx__
000000000080080000800800000990000000000000000000007e7e0000cccc000000000000000000000000000000000000000000000000000000000000000000
00000000008008000080080000099000008118000000000007e77e7000cccc000000000000000000000000000000000000000000000000000000000000000000
00000000008888000088880000099000088cc88000000000e77e77e700cccc000000000000000000000000000000000000000000000000000000000000000000
000000000881188008811880000000008808808800000000ee7e7ee700cccc000000000000000000000000000000000000000000000000000000000000000000
00000000088cc880088cc8800000000080088008000000007e77e77e00cccc000000000000000000000000000000000000000000000000000000000000000000
000000000808808008088080000000000088880000000000778888ee00cccc000000000000000000000000000000000000000000000000000000000000000000
00000000000a00000000a0000000000000890800000000000888888000cccc000000000000000000000000000000000000000000000000000000000000000000
000000000000a000000a0000000000000000900000000000008cc80000cccc000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000bb70b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000bb77b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000bb77b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000b0bbb0b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000b00b000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000080800000606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888880006666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088800000666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
