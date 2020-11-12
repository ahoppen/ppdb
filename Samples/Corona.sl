bool aliceInfectious = true
bool bobInfected = false
while aliceInfectious {
  prob 0.1 {
    bobInfected = true
  }
  prob 0.6 {
    aliceInfectious = false
  }
}
