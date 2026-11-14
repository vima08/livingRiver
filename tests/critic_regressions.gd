extends SceneTree
var game: Node
var failures := 0
func _initialize():
 call_deferred("run")
func check(ok: bool, label: String):
 print(("PASS " if ok else "FAIL ") + label)
 if not ok: failures += 1
func run():
 game=load("res://scenes/main.tscn").instantiate()
 game.set_meta("test_mode",true)
 root.add_child(game)
 game.set_physics_process(false)
 for action in ["steer_left","steer_right","accelerate","slow_down","brake","deliver","restart","start_run","pause_run"]:
  check(InputMap.has_action(action) and InputMap.action_get_events(action).size()>0,"Runtime mapping " + action)
 game.start_run()
 game.select_gear(2)
 for i in range(11000):
  var c=game.pilot_controls()
  game.simulate(1.0/60,c[0],false,false)
  if game.boat_pos.y<=-26150: break
 check(game.state=="running" and not game.delivered,"Dock can be deliberately overshot while alive")
 for i in range(60): game.simulate(1.0/60,Vector2(0,1),false,false)
 game.select_gear(9)
 for i in range(150): game.simulate(1.0/60,Vector2(0,-1),false,false)
 for i in range(180): game.simulate(1.0/60,Vector2.ZERO,true,true)
 check(game.state=="success" and game.delivered,"Overshoot recovery: S brake, 9 reverse, W throttle then Space+E delivers")
 game.reset_run()
 game.start_run()
 var r=game.rocks[0]
 game.boat_pos=r.pos+Vector2(0,r.radius+34)
 game.velocity=Vector2(0,-150)
 game.simulate(1.0/60,Vector2.ZERO,false,false)
 check(game.hull<100,"Bow collision catches visible 35-unit hull")
 check(game.impact_flash>0,"Collision feedback signal activated")
 game.fuel=0.001
 game.simulate(1.0/60,Vector2.ZERO,true,false)
 var snapshot=[game.boat_pos,game.velocity,game.fuel,game.hull,game.elapsed]
 game.simulate(5,Vector2.ONE,false,true)
 check(snapshot==[game.boat_pos,game.velocity,game.fuel,game.hull,game.elapsed],"Failure freezes complete physical and resource snapshot")
 # Exercise actual action polling inside engine physics, rather than calling reset directly.
 game.set_physics_process(true)
 Input.action_press("restart")
 await physics_frame
 await physics_frame
 Input.action_release("restart")
 game.set_physics_process(false)
 check(game.state=="ready" and game.fuel==100 and game.hull==100 and game.elapsed==0 and not game.pickup_taken and not game.delivered,"R action returns a clean briefing through actual physics input polling")
 print("Critic failures: ",failures)
 quit(failures)
