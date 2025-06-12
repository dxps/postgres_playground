package repos

import (
	"fmt"
	"time"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
)

type FactsRepo struct {
	db *sqlx.DB
}

func NewFactsRepo(
	driver string,
	dataSourceName string,
	maxOpenConns int,
	maxIdleConns int,
	maxIdleTime string) (*FactsRepo, error) {

	connMaxIdleTime, err := time.ParseDuration(maxIdleTime)
	if err != nil {
		return nil, err
	}
	db, err := sqlx.Connect("postgres", dataSourceName)
	if err != nil {
		return nil, fmt.Errorf("error opening postgres db: %w", err)
	}
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("error connecting to postgres db: %w", err)
	}
	db.DB.SetMaxOpenConns(maxOpenConns)
	db.DB.SetMaxIdleConns(maxIdleConns)
	db.DB.SetConnMaxIdleTime(connMaxIdleTime)

	return &FactsRepo{db}, nil
}
