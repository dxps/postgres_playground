package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"path"
	"sync"

	"github.com/dxps/postgres_playground/optimistic_locking_example/internal/config"
	"github.com/dxps/postgres_playground/optimistic_locking_example/internal/logic"
	"github.com/dxps/postgres_playground/optimistic_locking_example/internal/repos"
	"github.com/sethvargo/go-envconfig"
)

func main() {

	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
		AddSource: true,
		Level:     slog.LevelDebug,
		ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
			if a.Key == slog.SourceKey {
				s := a.Value.Any().(*slog.Source)
				s.File = path.Base(s.File)
			}
			return a
		},
	}))
	slog.SetDefault(logger)

	slog.Info("Starting up ...")

	if err := envconfig.Process(context.Background(), &config.Cfg); err != nil {
		slog.Error("Failed to load config.", "error", err)
		return
	}
	slog.Info(fmt.Sprintf("Config loaded. Using %d workers.", config.Cfg.Workers))
	slog.Info("Connecting to database ...")

	r, err := repos.NewVerFactsRepo(
		config.Cfg.Db.Driver, config.Cfg.Db.DSN,
		config.Cfg.Db.MaxOpenConns, config.Cfg.Db.MaxIdleConns, config.Cfg.Db.MaxIdleTime,
	)
	if err != nil {
		slog.Error("Failed to create FactsRepo.", "error", err)
		return
	}
	slog.Info("Successfully connected to database.")

	var wg sync.WaitGroup
	wg.Add(config.Cfg.Workers)

	for i := range config.Cfg.Workers {
		go func() {
			defer wg.Done()
			if err := logic.DoWork(i+1, r); err != nil {
				slog.Error(fmt.Sprintf("Worker %d failed with '%v'.", i+1, err))
			}
		}()
	}

	slog.Info("Waiting for workers to finish ...")
	wg.Wait()
	slog.Info("All workers finished.")
}
