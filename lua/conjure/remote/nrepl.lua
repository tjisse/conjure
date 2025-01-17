local _0_0
do
  local name_0_ = "conjure.remote.nrepl"
  local module_0_
  do
    local x_0_ = package.loaded[name_0_]
    if ("table" == type(x_0_)) then
      module_0_ = x_0_
    else
      module_0_ = {}
    end
  end
  module_0_["aniseed/module"] = name_0_
  module_0_["aniseed/locals"] = ((module_0_)["aniseed/locals"] or {})
  module_0_["aniseed/local-fns"] = ((module_0_)["aniseed/local-fns"] or {})
  package.loaded[name_0_] = module_0_
  _0_0 = module_0_
end
local autoload = (require("conjure.aniseed.autoload")).autoload
local function _1_(...)
  local ok_3f_0_, val_0_ = nil, nil
  local function _1_()
    return {autoload("conjure.aniseed.core"), autoload("conjure.remote.transport.bencode"), autoload("conjure.client"), autoload("conjure.extract"), autoload("conjure.log"), autoload("conjure.net"), autoload("conjure.timer"), autoload("conjure.uuid")}
  end
  ok_3f_0_, val_0_ = pcall(_1_)
  if ok_3f_0_ then
    _0_0["aniseed/local-fns"] = {autoload = {a = "conjure.aniseed.core", bencode = "conjure.remote.transport.bencode", client = "conjure.client", extract = "conjure.extract", log = "conjure.log", net = "conjure.net", timer = "conjure.timer", uuid = "conjure.uuid"}}
    return val_0_
  else
    return print(val_0_)
  end
end
local _local_0_ = _1_(...)
local a = _local_0_[1]
local bencode = _local_0_[2]
local client = _local_0_[3]
local extract = _local_0_[4]
local log = _local_0_[5]
local net = _local_0_[6]
local timer = _local_0_[7]
local uuid = _local_0_[8]
local _2amodule_2a = _0_0
local _2amodule_name_2a = "conjure.remote.nrepl"
do local _ = ({nil, _0_0, nil, {{}, nil, nil, nil}})[2] end
local with_all_msgs_fn
do
  local v_0_
  do
    local v_0_0
    local function with_all_msgs_fn0(cb)
      local acc = {}
      local function _2_(msg)
        table.insert(acc, msg)
        if msg.status.done then
          return cb(acc)
        end
      end
      return _2_
    end
    v_0_0 = with_all_msgs_fn0
    _0_0["with-all-msgs-fn"] = v_0_0
    v_0_ = v_0_0
  end
  local t_0_ = (_0_0)["aniseed/locals"]
  t_0_["with-all-msgs-fn"] = v_0_
  with_all_msgs_fn = v_0_
end
local connect
do
  local v_0_
  do
    local v_0_0
    local function connect0(opts)
      local state = {["awaiting-process?"] = false, ["message-queue"] = {}, bc = bencode.new(), msgs = {}}
      local conn = {session = nil, state = state}
      local function enrich_status(msg)
        local ks = a.get(msg, "status")
        local status = {}
        local function _2_(k)
          return a.assoc(status, k, true)
        end
        a["run!"](_2_, ks)
        a.assoc(msg, "status", status)
        return msg
      end
      local function send(msg, cb)
        local msg_id = uuid.v4()
        a.assoc(msg, "id", msg_id)
        if (not msg.session and conn.session) then
          a.assoc(msg, "session", conn.session)
        end
        log.dbg("send", msg)
        local function _3_()
        end
        a["assoc-in"](state, {"msgs", msg_id}, {["sent-at"] = os.time(), cb = (cb or _3_), msg = msg})
        ; (conn.sock):write(bencode.encode(msg))
        return nil
      end
      local function process_message(err, chunk)
        if err then
          return opts["on-error"](err)
        elseif not chunk then
          return opts["on-error"]()
        else
          local function _2_(msg)
            log.dbg("receive", msg)
            enrich_status(msg)
            if msg.status["need-input"] then
              local function _3_()
                return send({op = "stdin", session = msg.session, stdin = ((extract.prompt("Input required: ") or "") .. "\n")})
              end
              client.schedule(_3_)
            end
            do
              local cb = a["get-in"](state, {"msgs", msg.id, "cb"}, opts["default-callback"])
              local ok_3f, err0 = pcall(cb, msg)
              if not ok_3f then
                opts["on-error"](err0)
              end
            end
            if msg.status.done then
              a["assoc-in"](state, {"msgs", msg.id}, nil)
            end
            return opts["on-message"](msg)
          end
          return a["run!"](_2_, bencode["decode-all"](state.bc, chunk))
        end
      end
      local function process_message_queue()
        state["awaiting-process?"] = false
        if not a["empty?"](state["message-queue"]) then
          local msgs = state["message-queue"]
          state["message-queue"] = {}
          local function _2_(args)
            return process_message(unpack(args))
          end
          return a["run!"](_2_, msgs)
        end
      end
      local function enqueue_message(...)
        table.insert(state["message-queue"], {...})
        if not state["awaiting-process?"] then
          state["awaiting-process?"] = true
          return client.schedule(process_message_queue)
        end
      end
      local function handle_connect_fn()
        local function _2_(err)
          if err then
            return opts["on-failure"](err)
          else
            (conn.sock):read_start(client.wrap(enqueue_message))
            return opts["on-success"]()
          end
        end
        return client["schedule-wrap"](_2_)
      end
      conn = a["merge!"](conn, {send = send}, net.connect({cb = handle_connect_fn(), host = opts.host, port = opts.port}))
      return conn
    end
    v_0_0 = connect0
    _0_0["connect"] = v_0_0
    v_0_ = v_0_0
  end
  local t_0_ = (_0_0)["aniseed/locals"]
  t_0_["connect"] = v_0_
  connect = v_0_
end
return nil