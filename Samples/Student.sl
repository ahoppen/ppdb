bool examDifficult = false
prob 0.4 {
    examDifficult = true
}
bool studentIntelligent = false
prob 0.3 {
    studentIntelligent = true
}

bool goodGrade = false
if studentIntelligent {
    if examDifficult {
        prob 0.5 {
            goodGrade = false
        } else {
            goodGrade = true
        }
    } else {
        prob 0.9 {
            goodGrade = false
        } else {
            goodGrade = true
        }
    }
} else {
    if examDifficult {
        prob 0.05 {
            goodGrade = false
        } else {
            goodGrade = true
        }
    } else {
        prob 0.3 {
            goodGrade = false
        } else {
            goodGrade = true
        }
    }
}

bool satisfied = false
if studentIntelligent {
    prob 0.2 {
        satisfied = false
    } else {
        satisfied = true
    }
} else {
    prob 0.95 {
        satisfied = false
    } else {
        satisfied = true
    }
}

bool recommendationLetter = false
if goodGrade {
    prob 0.4 {
        recommendationLetter = false
    } else {
        recommendationLetter = true
    }
} else {
    prob 0.9 {
        recommendationLetter = false
    } else {
        recommendationLetter = true
    }
}

observe(recommendationLetter)
