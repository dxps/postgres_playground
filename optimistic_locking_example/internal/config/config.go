package config

type Config struct {
	Db struct {
		Driver       string `env:"DB_DRIVER, default=postgres"`
		DSN          string `env:"DB_DSN, default=postgres://optimistic_locking:optimistic_locking@localhost:5457/optimistic_locking?sslmode=disable&timezone=Europe/Bucharest"`
		MaxOpenConns int    `env:"DB_MAX_OPEN_CONNS, default=50"`
		MaxIdleConns int    `env:"DB_MAX_IDLE_CONNS, default=2"`
		MaxIdleTime  string `env:"DB_MAX_IDLE_TIME, default=1m"`
	}
	Workers int `env:"WORKERS, default=10"`
}

// A global variable to hold the configuration.
var Cfg Config
