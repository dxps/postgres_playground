package logic

import (
	"fmt"
	"math/rand/v2"

	"github.com/dxps/postgres_playground/optimistic_locking_example/internal/config"
	"github.com/dxps/postgres_playground/optimistic_locking_example/internal/repos"
)

// Run upserts (updates or inserts, if not exists) executed by a number of workers.
// Each worker is a goroutine that has its number (from 1 to `workers` provided number)
// and tries to:
// 1. Do an upsert with its own id.
// 2. Do an upsert a random id, out of the ones within the range 1..{workers}.
func DoWork(workerID int, r *repos.VerFactsRepo) error {

	if err := r.Add(workerID); err != nil {
		return fmt.Errorf("[worker %d] Add failed with '%w'", workerID, err)
	}
	n := rand.IntN(config.Cfg.Workers)

	if err := r.SetAsProcessed(n); err != nil {
		return fmt.Errorf("[worker %d] SetAsProcessed failed with '%w'", workerID, err)
	}

	return nil
}
