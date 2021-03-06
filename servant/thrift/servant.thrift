namespace go   fun.rpc
namespace py   fun.rpc
namespace php  fun.rpc
namespace java fun.rpc

exception TCacheMissed {
    11: optional string message
}

exception TMongoNotFound {
    11: optional string message
}

exception TMongoDegrade {
    11: optional string message
}

exception TMongoReadOnly {
    11: optional string message
}

struct TMemcacheData {
    1: required binary data
    2: required i32 flags
}

struct TCouchbaseData {
    1: required bool missed
    2: required binary data
}

struct MysqlResult {
    1:required i64 rowsAffected
    2:required i64 lastInsertId
    3:required list<string> cols
    4:required list<list<string>> rows
}

struct MysqlMergeResult {
    1:required bool ok
    2:required string newVal
}

struct Context {

    /**
     * Request id.
     *
     * for thrift RPC, this is session id because this is within a single tcp conn.
     *
     * RPC client is reponsible to generate this rid.
     */ 
    1:required i64 rid

    /**
     * Reason of call RPC.
     *
     * e,g. controler.action name or batch cmds
     */
    2:required string reason

    /**
     * User id.
     *
     */
    3:required i64 uid

    /**
     * If recv this flag, it means sticky request is sent
     * and I will be the final servant in the chain
     */
    4:optional bool sticky
}

/**
 * Thrift don't support service multiplex, so we have to bury all
 * services into the giant FunServant.
 *
 * We don't want to use different port for different service for 
 * multiplex of service, that will lead to complexity for client.
 */
service FunServant {

    //=================
    // zk section
    //=================

    bool zk_create(
        1: required Context ctx,
        2: required string path,
        3: required string data
    ),

    list<string> zk_children(
        1: required Context ctx,
        2: required string path
    ),

    bool zk_del(
        1: required Context ctx,
        2: required string path
    ),

    /**
     * Just for QPS throughput testing.
     */
    i32 noop(
        1: required i32 x
    ),


    /**
     * Ping.
     *
     * @return string - returns current fae version
     */
    string ping(
        1: required Context ctx
    ),

    /**
     * Lock a key across the fae cluster.
     *
     * @return bool - success?
     */
    bool lock(
        1: Context ctx,
        2: string reason,
        3: string key
    ),

    /**
     * Unlock a key across the fae cluster.
     */
    void unlock(
        1: Context ctx,
        2: string reason,
        3: string key
    ),

    /**
     * ID generator.
     *
     * Internally calls id_next_with_tag with tag=0
     *
     * If return 0, it means failure.
     */
    i64 id_next(
        1: required Context ctx
    ),

    /**
     * ID generator with tag.
     *
     * If return 0, it means failure.
     */
    i64 id_next_with_tag(
        1: required Context ctx,
        2: i16 tag
    ),

    /**
     * Decode an id that was generated with id_next_with_tag.
     *
     * returns (ts, tag, wid, seq).
     */
    list<i64> id_decode(
        1: required Context ctx,
        2: i64 id
    ),

    //====================
    // local cache section
    //====================

    bool lc_set(
        1: required Context ctx, 
        2: required string key, 
        3: required binary value
    ),

    binary lc_get(
        1: required Context ctx, 
        2: required string key
    ) throws (
        1: TCacheMissed miss
    ),

    void lc_del(
        1: required Context ctx, 
        2: required string key
    ),

    //=================
    // redis section
    //=================
    string rd_call(
        1: required Context ctx, 
        2: required string cmd,
        3: required string pool,
        4: required list<string> keysAndArgs
    ),

    //=================
    // memcache section
    //=================

    /**
     * Set.
     *
     * @param Context ctx - Request context info.
     * @param string pool - mc pool name
     * @param string key -
     * @param TMemcacheData value -
     * @param i32 expiration - in seconds: either a relative time from now (up to 1 month), or 
     *     an absolute Unix epoch time. Zero means the Item has no expiration time.
     */
    bool mc_set(
        1: required Context ctx, 
        2: required string pool,
        3: required string key, 
        4: required TMemcacheData value, 
        5: required i32 expiration
    ),

    /**
     * Get.
     *
     * @param Context ctx - Request context info.
     * @param string pool -
     * @param string key -
     * @return TMemcacheData - Value of the key
     */
    TMemcacheData mc_get(
        1: required Context ctx, 
        2: required string pool,
        3: required string key
    ) throws (
        1: TCacheMissed miss
    ),

    /**
     * Add.
     *
     * @param Context ctx - Request context info.
     * @param string pool -
     * @param string key -
     * @param TMemcacheData value - Value of the key
     * @param i32 expiration -
     * @return bool - False if the key already exists.
     */
    bool mc_add(
        1: required Context ctx, 
        2: required string pool,
        3: required string key, 
        4: required TMemcacheData value, 
        5: required i32 expiration
    ),

    /**
     * Delete.
     *
     * @param Context ctx - Request context info.
     * @param string pool -
     * @param string key -
     * @return bool - True if Success 
     */
    bool mc_delete(
        1: required Context ctx, 
        2: required string pool,
        3: required string key
    ),

    /**
     * Increment.
     *
     * @param Context ctx - Request context info.
     * @param string pool -
     * @param string key -
     * @param i32 delta - If negative, means decrement
     * @return binary - New value of the key
     */
    i64 mc_increment(
        1: required Context ctx, 
        2: required string pool,
        3: required string key, 
        4: required i64 delta
    ),

    //=================
    // mongodb section
    // use binary for 
    // all bson codec
    //=================

    binary mg_find_one(
        1: required Context ctx, 
        2: string pool,
        3: string table,
        4: i32 shardId,
        /** where condition */
        5: binary query,
        6: binary fields
    ) throws (
        1: TMongoNotFound miss
    ),

    list<binary> mg_find_all(
        1: required Context ctx, 
        2: string pool,
        3: string table,
        4: i32 shardId,
        5: binary query,
        6: binary fields,
        7: i32 limit,
        8: i32 skip,
        9: list<string> orderBy
    ),

    binary mg_find_id(
        1: required Context ctx,
        2: string pool,
        3: string table,
        4: i32 shardId,
        5: binary id
    ),

    i32 mg_count(
        1: required Context ctx,
        2: string pool,
        3: string table,
        4: i32 shardId,
        5: binary query
    ),

    bool mg_update(
        1: required Context ctx, 
        2: string pool,
        3: string table,
        4: i32 shardId,
        5: binary query,
        6: binary change
    ),

    bool mg_update_id(
        1: required Context ctx, 
        2: string pool,
        3: string table,
        4: i32 shardId,
        5: i32 id,
        6: binary change
    ),

    bool mg_upsert(
        1: required Context ctx, 
        2: string pool,
        3: string table,
        4: i32 shardId,
        5: binary query,
        6: binary change
    ),

    bool mg_upsert_id(
        1: required Context ctx, 
        2: string pool,
        3: string table,
        4: i32 shardId,
        5: i32 id,
        6: binary change
    ),

    bool mg_insert(
        1: required Context ctx, 
        2: string pool,
        3: string table,
        4: i32 shardId,
        5: binary doc
    ),

    bool mg_inserts(
        1: required Context ctx, 
        2: string pool,
        3: string table,
        4: i32 shardId,
        5: list<binary> docs
    ),

    bool mg_delete(
        1: required Context ctx, 
        2: string pool,
        3: string table,
        4: i32 shardId,
        5: binary query
    ),

    binary mg_find_and_modify(
        1: required Context ctx, 
        2: string pool,
        3: string table,
        4: i32 shardId,
        5: binary query,
        6: binary change,
        7: bool upsert,
        8: bool remove,
        9: bool returnNew
    ),

    //=================
    // mysql section
    //=================

    i64 my_bulk_exec(
        1: required Context ctx,
        2: list<string> pool,
        3: list<string> table,
        4: list<i64> hintId,
        5: list<string> sql,
        6: list<list<string>> argv,
        7: list<string> cacheKey
    ),

    MysqlResult my_query(
        1: required Context ctx,
        2: string pool,
        3: string table,
        4: i64 hintId,
        5: string sql,
        6: list<string> argv,
        7: string cacheKey
    ),

    /**
     * Query across all shards of a table.
     *
     */
    MysqlResult my_query_shards(
        1: required Context ctx,
        2: string pool,
        3: string table,
        4: string sql,
        5: list<string> argv
    ),

    /**
     * Atomically merge a blob column that is encoded in json.
     * Specifically used for concurrent update.
     */
    MysqlMergeResult my_merge(
        1: required Context ctx,
        2: string pool,
        3: string table,
        4: i64 hintId,
        5: string where,
        6: string key,
        7: string column,
        8: string jsonValue
    ),

    /** 
     * Manually evict a mysql cache by cacheKey.
     */
    void my_evict(
        1: required Context ctx,
        2: string cacheKey
    ),

    //=================
    // couchbase section
    //=================

    bool cb_del(
        1: Context ctx,
        2: string bucket,
        3: string key,
    ),

    void cb_append(
        1: Context ctx,
        2: string bucket,
        3: string key,
        4: binary val,
    ),

    bool cb_add(
        1: Context ctx,
        2: string bucket,
        3: string key,
        4: binary val,
        5: i32 expire,
    ),

    void cb_set(
        1: Context ctx,
        2: string bucket,
        3: string key,
        4: binary val,
        5: i32 expire,
    ),

    TCouchbaseData cb_get(
        1: Context ctx,
        2: string bucket,
        3: string key
    ),

    map<string, binary> cb_gets(
        1: Context ctx,
        2: string bucket,
        3: list<string> keys
    ),

}
