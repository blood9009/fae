package config

import (
	"fmt"
	conf "github.com/funkygao/jsconf"
	log "github.com/funkygao/log4go"
	"time"
)

type ConfigMysqlServer struct {
	Pool         string
	Host         string
	Port         string
	User         string
	Pass         string
	DbName       string
	Charset      string
	ShardBaseNum int

	conf *ConfigMysql

	dsn string // cache of op result
}

func (this *ConfigMysqlServer) loadConfig(section *conf.Conf) {
	this.Pool = section.String("pool", "")
	this.Host = section.String("host", "")
	this.Port = section.String("port", "3306")
	this.DbName = section.String("db", "")
	this.ShardBaseNum = section.Int("shard_base_num", this.ShardBaseNum)
	this.User = section.String("username", "")
	this.Pass = section.String("password", "")
	this.Charset = section.String("charset", "utf8")
	if this.Host == "" ||
		this.Port == "" ||
		this.Pool == "" ||
		this.DbName == "" {
		panic("required field missing")
	}

	this.dsn = ""
	if this.User != "" {
		this.dsn = this.User + ":"
		if this.Pass != "" {
			this.dsn += this.Pass
		}
	}
	this.dsn += fmt.Sprintf("@tcp(%s:%s)/%s?", this.Host, this.Port, this.DbName)
	if this.Charset != "" {
		this.dsn += "charset=" + this.Charset
	}
	if this.conf.ConnectTimeout.Seconds() > 0 {
		this.dsn += "&timeout=" + this.conf.ConnectTimeout.String()
	}
}

func (this *ConfigMysqlServer) DSN() string {
	return this.dsn
}

type ConfigMysql struct {
	ShardBaseNum          int
	ShardStrategy         string
	ConnectTimeout        time.Duration
	IoTimeout             time.Duration   // FIXME not used yet
	GlobalPools           map[string]bool // non-sharded pools
	MaxIdleConnsPerServer int
	MaxConnsPerServer     int
	HeartbeatInterval     int

	// cache related
	CacheStore            string
	CacheStoreRedisPool   string
	CacheStoreMemMaxItems int
	CacheKeyHash          bool

	Breaker ConfigBreaker
	Servers map[string]*ConfigMysqlServer // key is pool

}

func (this *ConfigMysql) Enabled() bool {
	return len(this.Servers) > 0
}

func (this *ConfigMysql) Pools() (pools []string) {
	poolsMap := make(map[string]bool)
	for _, server := range this.Servers {
		poolsMap[server.Pool] = true
	}
	for poolName, _ := range poolsMap {
		pools = append(pools, poolName)
	}
	return
}

func (this *ConfigMysql) LoadConfig(cf *conf.Conf) {
	this.GlobalPools = make(map[string]bool)
	for _, p := range cf.StringList("global_pools", nil) {
		this.GlobalPools[p] = true
	}
	this.ShardBaseNum = cf.Int("shard_base_num", 100000)
	this.ShardStrategy = cf.String("shard_strategy", "standard")
	this.ConnectTimeout = cf.Duration("connect_timeout", 0)
	this.IoTimeout = cf.Duration("io_timeout", 30*time.Second)
	this.MaxIdleConnsPerServer = cf.Int("max_idle_conns_per_server", 2)
	this.MaxConnsPerServer = cf.Int("max_conns_per_server",
		this.MaxIdleConnsPerServer*5)
	this.HeartbeatInterval = cf.Int("heartbeat_interval", 120)
	this.CacheStore = cf.String("cache_store", "mem")
	this.CacheStoreMemMaxItems = cf.Int("cache_store_mem_max_items", 10<<20)
	this.CacheStoreRedisPool = cf.String("cache_store_redis_pool", "db_cache")
	this.CacheKeyHash = cf.Bool("cache_key_hash", true)
	section, err := cf.Section("breaker")
	if err == nil {
		this.Breaker.loadConfig(section)
	}
	this.Servers = make(map[string]*ConfigMysqlServer)
	for i := 0; i < len(cf.List("servers", nil)); i++ {
		section, err := cf.Section(fmt.Sprintf("servers[%d]", i))
		if err != nil {
			panic(err)
		}

		server := new(ConfigMysqlServer)
		server.conf = this
		server.ShardBaseNum = this.ShardBaseNum
		server.loadConfig(section)
		this.Servers[server.Pool] = server
	}

	log.Debug("mysql conf: %+v", *this)
}
