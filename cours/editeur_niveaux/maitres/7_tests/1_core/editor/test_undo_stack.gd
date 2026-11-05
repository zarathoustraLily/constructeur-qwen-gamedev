extends GdUnitTestSuite
## L'historique : annuler et refaire parcourent les instantanés ; un nouveau pas après une annulation oublie ce qu'on
## avait annulé ; un instantané rendu est une copie ; au-delà du plafond, les plus anciens sont oubliés ; chaque état a
## son numéro de révision.


func _room(display_name: String) -> RoomData:
	var room: RoomData = RoomData.new()
	room.display_name = display_name
	return room


func test_annuler_et_refaire_parcourent_les_etats() -> void:
	var stack: UndoStack = UndoStack.new()
	stack.reset(_room("a"))
	stack.push(_room("b"))
	assert_bool(stack.can_undo()).is_true()
	assert_str(stack.undo().display_name).is_equal("a")
	assert_bool(stack.can_redo()).is_true()
	assert_str(stack.redo().display_name).is_equal("b")
	assert_bool(stack.can_redo()).is_false()


func test_un_pas_apres_une_annulation_oublie_la_suite() -> void:
	var stack: UndoStack = UndoStack.new()
	stack.reset(_room("a"))
	stack.push(_room("b"))
	stack.undo()
	stack.push(_room("c"))
	assert_bool(stack.can_redo()).is_false()
	assert_str(stack.undo().display_name).is_equal("a")


func test_un_instantane_rendu_est_une_copie() -> void:
	var stack: UndoStack = UndoStack.new()
	stack.reset(_room("a"))
	var copy: RoomData = stack.current()
	copy.display_name = "changé"
	assert_str(stack.current().display_name).is_equal("a")


func test_au_dela_du_plafond_les_plus_anciens_sont_oublies() -> void:
	var stack: UndoStack = UndoStack.new()
	stack.reset(_room("0"))
	for i: int in range(1, UndoStack.MAX_STATES + 5):
		stack.push(_room(str(i)))
	var steps: int = 0
	while stack.can_undo():
		stack.undo()
		steps += 1
	assert_int(steps).is_equal(UndoStack.MAX_STATES - 1)
	assert_str(stack.current().display_name).is_equal("5")


func test_chaque_etat_a_sa_revision() -> void:
	var stack: UndoStack = UndoStack.new()
	stack.reset(_room("a"))
	var first: int = stack.revision()
	stack.push(_room("b"))
	assert_int(stack.revision()).is_not_equal(first)
	stack.undo()
	assert_int(stack.revision()).is_equal(first)
