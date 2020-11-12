int initialCowboy = 1
prob 0.5 {
    initialCowboy = 2
}
int turn = initialCowboy
bool alive = true
while alive {
  prob 0.5 {
    if turn == 1 {
      turn = 2
    } else {
      turn = 1
    }
  } else {
    alive = false
  }
}
observe(turn == 2)
