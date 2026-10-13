
---@diagnostic disable: undefined-field

local ffi = require("ffi")

ffi.cdef([[
    typedef struct OrtEnv OrtEnv;
    typedef struct OrtSession OrtSession;
    typedef struct OrtSessionOptions OrtSessionOptions;
    typedef struct OrtRunOptions OrtRunOptions;
    typedef struct OrtStatus OrtStatus;
    typedef struct OrtAllocator OrtAllocator;
    typedef struct OrtMemoryInfo OrtMemoryInfo;
    typedef struct OrtValue OrtValue;
    typedef struct OrtTypeInfo OrtTypeInfo;
    typedef struct OrtTensorTypeAndShapeInfo OrtTensorTypeAndShapeInfo;
    typedef struct OrtCustomOpDomain OrtCustomOpDomain;
    typedef struct OrtCustomOp OrtCustomOp;
    typedef int32_t OrtErrorCode;
    typedef wchar_t ORTCHAR_T;

    typedef enum OrtLoggingLevel {
        ORT_LOGGING_LEVEL_VERBOSE = 0,
        ORT_LOGGING_LEVEL_INFO = 1,
        ORT_LOGGING_LEVEL_WARNING = 2,
        ORT_LOGGING_LEVEL_ERROR = 3,
        ORT_LOGGING_LEVEL_FATAL = 4
    } OrtLoggingLevel;

    typedef enum OrtAllocatorType {
        ORT_ALLOCATOR_INVALID = 0,
        ORT_ARENA_ALLOCATOR = 1,
        ORT_HUGEPAGES_ALLOCATOR = 2,
        ORT_DEVICE_ALLOCATOR = 3,
        ORT_PINNED_ALLOCATOR = 4
    } OrtAllocatorType;

    typedef enum OrtMemType {
        OrtMemTypeDefault = 0,
        OrtMemTypeCPU = -1,
        OrtMemTypeCPUOutput = -1
    } OrtMemType;

    typedef enum GraphOptimizationLevel {
        ORT_DISABLE_ALL = 0,
        ORT_ENABLE_BASIC = 1,
        ORT_ENABLE_EXTENDED = 2,
        ORT_ENABLE_LAYOUT = 3,
        ORT_ENABLE_ALL = 99
    } GraphOptimizationLevel;

    typedef enum ONNXTensorElementDataType {
        ONNX_TENSOR_ELEMENT_DATA_TYPE_UNDEFINED = 0,
        ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT = 1,
        ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT8 = 2,
        ONNX_TENSOR_ELEMENT_DATA_TYPE_INT8 = 3,
        ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT16 = 4,
        ONNX_TENSOR_ELEMENT_DATA_TYPE_INT16 = 5,
        ONNX_TENSOR_ELEMENT_DATA_TYPE_INT32 = 6,
        ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64 = 7,
        ONNX_TENSOR_ELEMENT_DATA_TYPE_STRING = 8,
        ONNX_TENSOR_ELEMENT_DATA_TYPE_BOOL = 9,
        ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT16 = 10,
        ONNX_TENSOR_ELEMENT_DATA_TYPE_DOUBLE = 11,
        ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT32 = 12,
        ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT64 = 13,
        ONNX_TENSOR_ELEMENT_DATA_TYPE_COMPLEX64 = 14,
        ONNX_TENSOR_ELEMENT_DATA_TYPE_COMPLEX128 = 15,
        ONNX_TENSOR_ELEMENT_DATA_TYPE_BFLOAT16 = 16
    } ONNXTensorElementDataType;

    typedef struct OrtApi OrtApi;

    typedef struct OrtApiBase {
        const OrtApi* (__stdcall *GetApi)(uint32_t version);
        const char* (__stdcall *GetVersionString)(void);
    } OrtApiBase;

    struct OrtApi {
        OrtStatus* (__stdcall *CreateStatus)(OrtErrorCode code, const char* msg);
        OrtErrorCode (__stdcall *GetErrorCode)(const OrtStatus* status);
        const char* (__stdcall *GetErrorMessage)(const OrtStatus* status);
        OrtStatus* (__stdcall *CreateEnv)(OrtLoggingLevel log_severity_level, const char* logid,
            OrtEnv** out);
        OrtStatus* (__stdcall *CreateEnvWithCustomLogger)(void* logging_function,
            void* logger_param, OrtLoggingLevel log_severity_level, const char* logid,
            OrtEnv** out);
        OrtStatus* (__stdcall *EnableTelemetryEvents)(const OrtEnv* env);
        OrtStatus* (__stdcall *DisableTelemetryEvents)(const OrtEnv* env);
        OrtStatus* (__stdcall *CreateSession)(const OrtEnv* env, const wchar_t* model_path,
            const OrtSessionOptions* options, OrtSession** out);
        OrtStatus* (__stdcall *CreateSessionFromArray)(const OrtEnv* env,
            const void* model_data, size_t model_data_length,
            const OrtSessionOptions* options, OrtSession** out);
        OrtStatus* (__stdcall *Run)(OrtSession* session, const OrtRunOptions* run_options,
            const char* const* input_names, const OrtValue* const* inputs, size_t input_len,
            const char* const* output_names, size_t output_names_len, OrtValue** outputs);
        OrtStatus* (__stdcall *CreateSessionOptions)(OrtSessionOptions** options);
        OrtStatus* (__stdcall *SetOptimizedModelFilePath)(OrtSessionOptions* options,
            const ORTCHAR_T* optimized_model_filepath);
        OrtStatus* (__stdcall *CloneSessionOptions)(const OrtSessionOptions* options,
            OrtSessionOptions** out);
        OrtStatus* (__stdcall *SetSessionExecutionMode)(OrtSessionOptions* options, int execution_mode);
        OrtStatus* (__stdcall *EnableProfiling)(OrtSessionOptions* options, const ORTCHAR_T* profile_file_prefix);
        OrtStatus* (__stdcall *DisableProfiling)(OrtSessionOptions* options);
        OrtStatus* (__stdcall *EnableMemPattern)(OrtSessionOptions* options);
        OrtStatus* (__stdcall *DisableMemPattern)(OrtSessionOptions* options);
        OrtStatus* (__stdcall *EnableCpuMemArena)(OrtSessionOptions* options);
        OrtStatus* (__stdcall *DisableCpuMemArena)(OrtSessionOptions* options);
        OrtStatus* (__stdcall *SetSessionLogId)(OrtSessionOptions* options, const char* logid);
        OrtStatus* (__stdcall *SetSessionLogVerbosityLevel)(OrtSessionOptions* options,
            int session_log_verbosity_level);
        OrtStatus* (__stdcall *SetSessionLogSeverityLevel)(OrtSessionOptions* options,
            int session_log_severity_level);
        OrtStatus* (__stdcall *SetSessionGraphOptimizationLevel)(OrtSessionOptions* options,
            GraphOptimizationLevel graph_optimization_level);
        OrtStatus* (__stdcall *SetIntraOpNumThreads)(OrtSessionOptions* options, int intra_op_num_threads);
        OrtStatus* (__stdcall *SetInterOpNumThreads)(OrtSessionOptions* options, int inter_op_num_threads);
        OrtStatus* (__stdcall *CreateCustomOpDomain)(const char* domain, OrtCustomOpDomain** out);
        OrtStatus* (__stdcall *CustomOpDomain_Add)(OrtCustomOpDomain* custom_op_domain,
            const OrtCustomOp* op);
        OrtStatus* (__stdcall *AddCustomOpDomain)(OrtSessionOptions* options,
            OrtCustomOpDomain* custom_op_domain);
        OrtStatus* (__stdcall *RegisterCustomOpsLibrary)(OrtSessionOptions* options,
            const char* library_path, void** library_handle);
        OrtStatus* (__stdcall *SessionGetInputCount)(const OrtSession* session, size_t* out);
        OrtStatus* (__stdcall *SessionGetOutputCount)(const OrtSession* session, size_t* out);
        OrtStatus* (__stdcall *SessionGetOverridableInitializerCount)(const OrtSession* session,
            size_t* out);
        OrtStatus* (__stdcall *SessionGetInputTypeInfo)(const OrtSession* session, size_t index,
            OrtTypeInfo** type_info);
        OrtStatus* (__stdcall *SessionGetOutputTypeInfo)(const OrtSession* session, size_t index,
            OrtTypeInfo** type_info);
        OrtStatus* (__stdcall *SessionGetOverridableInitializerTypeInfo)(const OrtSession* session,
            size_t index, OrtTypeInfo** type_info);
        OrtStatus* (__stdcall *SessionGetInputName)(const OrtSession* session, size_t index,
            OrtAllocator* allocator, char** value);
        OrtStatus* (__stdcall *SessionGetOutputName)(const OrtSession* session, size_t index,
            OrtAllocator* allocator, char** value);
        OrtStatus* (__stdcall *SessionGetOverridableInitializerName)(const OrtSession* session,
            size_t index, OrtAllocator* allocator, char** value);
        OrtStatus* (__stdcall *CreateRunOptions)(OrtRunOptions** out);
        OrtStatus* (__stdcall *RunOptionsSetRunLogVerbosityLevel)(OrtRunOptions* options, int log_verbosity_level);
        OrtStatus* (__stdcall *RunOptionsSetRunLogSeverityLevel)(OrtRunOptions* options, int log_severity_level);
        OrtStatus* (__stdcall *RunOptionsSetRunTag)(OrtRunOptions* options, const char* run_tag);
        OrtStatus* (__stdcall *RunOptionsGetRunLogVerbosityLevel)(const OrtRunOptions* options, int* out);
        OrtStatus* (__stdcall *RunOptionsGetRunLogSeverityLevel)(const OrtRunOptions* options, int* out);
        OrtStatus* (__stdcall *RunOptionsGetRunTag)(const OrtRunOptions* options, const char** out);
        OrtStatus* (__stdcall *RunOptionsSetTerminate)(OrtRunOptions* options);
        OrtStatus* (__stdcall *RunOptionsUnsetTerminate)(OrtRunOptions* options);
        OrtStatus* (__stdcall *CreateTensorAsOrtValue)(OrtAllocator* allocator,
            const int64_t* shape, size_t shape_len, ONNXTensorElementDataType type,
            OrtValue** out);
        OrtStatus* (__stdcall *CreateTensorWithDataAsOrtValue)(const OrtMemoryInfo* info,
            void* p_data, size_t p_data_len, const int64_t* shape, size_t shape_len,
            ONNXTensorElementDataType type, OrtValue** out);
        OrtStatus* (__stdcall *IsTensor)(const OrtValue* value, int* out);
        OrtStatus* (__stdcall *GetTensorMutableData)(OrtValue* value, void** out);
        OrtStatus* (__stdcall *FillStringTensor)(OrtValue* value, const char* const* s, size_t s_len);
        OrtStatus* (__stdcall *GetStringTensorDataLength)(const OrtValue* value, size_t* len);
        OrtStatus* (__stdcall *GetStringTensorContent)(const OrtValue* value, void* s,
            size_t s_len, size_t* offsets, size_t offsets_len);
        OrtStatus* (__stdcall *CastTypeInfoToTensorInfo)(const OrtTypeInfo* type_info,
            const OrtTensorTypeAndShapeInfo** out);
        OrtStatus* (__stdcall *GetOnnxTypeFromTypeInfo)(const OrtTypeInfo* type_info, int* out);
        OrtStatus* (__stdcall *CreateTensorTypeAndShapeInfo)(OrtTensorTypeAndShapeInfo** out);
        OrtStatus* (__stdcall *SetTensorElementType)(OrtTensorTypeAndShapeInfo* info,
            ONNXTensorElementDataType type);
        OrtStatus* (__stdcall *SetDimensions)(OrtTensorTypeAndShapeInfo* info,
            const int64_t* dim_values, size_t dim_count);
        OrtStatus* (__stdcall *GetTensorElementType)(const OrtTensorTypeAndShapeInfo* info,
            ONNXTensorElementDataType* out);
        OrtStatus* (__stdcall *GetDimensionsCount)(const OrtTensorTypeAndShapeInfo* info,
            size_t* out);
        OrtStatus* (__stdcall *GetDimensions)(const OrtTensorTypeAndShapeInfo* info,
            int64_t* dim_values, size_t dim_count);
        OrtStatus* (__stdcall *GetSymbolicDimensions)(const OrtTensorTypeAndShapeInfo* info,
            const char* const* dim_values, size_t dim_count);
        OrtStatus* (__stdcall *GetTensorShapeElementCount)(const OrtTensorTypeAndShapeInfo* info,
            size_t* out);
        OrtStatus* (__stdcall *GetTensorTypeAndShape)(const OrtValue* value,
            OrtTensorTypeAndShapeInfo** out);
        OrtStatus* (__stdcall *GetTypeInfo)(const OrtValue* value, OrtTypeInfo** out);
        OrtStatus* (__stdcall *GetValueType)(const OrtValue* value, int* out);
        OrtStatus* (__stdcall *CreateMemoryInfo)(const char* name, OrtAllocatorType type,
            int device_id, OrtMemType mem_type, OrtMemoryInfo** out);
        OrtStatus* (__stdcall *CreateCpuMemoryInfo)(OrtAllocatorType type, OrtMemType mem_type,
            OrtMemoryInfo** out);
        OrtStatus* (__stdcall *CompareMemoryInfo)(const OrtMemoryInfo* info1, const OrtMemoryInfo* info2, int* out);
        OrtStatus* (__stdcall *MemoryInfoGetName)(const OrtMemoryInfo* ptr, const char** out);
        OrtStatus* (__stdcall *MemoryInfoGetId)(const OrtMemoryInfo* ptr, int* out);
        OrtStatus* (__stdcall *MemoryInfoGetMemType)(const OrtMemoryInfo* ptr, OrtMemType* out);
        OrtStatus* (__stdcall *MemoryInfoGetType)(const OrtMemoryInfo* ptr, OrtAllocatorType* out);
        OrtStatus* (__stdcall *AllocatorAlloc)(OrtAllocator* ort_allocator, size_t size, void** out);
        OrtStatus* (__stdcall *AllocatorFree)(OrtAllocator* ort_allocator, void* p);
        OrtStatus* (__stdcall *AllocatorGetInfo)(const OrtAllocator* ort_allocator, const OrtMemoryInfo** out);
        OrtStatus* (__stdcall *GetAllocatorWithDefaultOptions)(OrtAllocator** out);
        void (__stdcall *ReleaseMemoryInfo)(OrtMemoryInfo* ptr);
        void (__stdcall *ReleaseTypeInfo)(OrtTypeInfo* ptr);
        void (__stdcall *ReleaseTensorTypeAndShapeInfo)(OrtTensorTypeAndShapeInfo* ptr);
        void (__stdcall *ReleaseValue)(OrtValue* value);
        void (__stdcall *ReleaseSession)(OrtSession* session);
        void (__stdcall *ReleaseSessionOptions)(OrtSessionOptions* options);
        void (__stdcall *ReleaseEnv)(OrtEnv* env);
    };

    const OrtApiBase* __stdcall OrtGetApiBase(void);
    int __stdcall MultiByteToWideChar(unsigned int CodePage, uint32_t dwFlags,
        const char* lpMultiByteStr, int cbMultiByte, wchar_t* lpWideCharStr,
        int cchWideChar);
]])

local ORT_API_VERSION = 18 -- compatible with ONNX Runtime 1.14+
local ORT_LOGGING_LEVEL_WARNING = 2
local ORT_ARENA_ALLOCATOR = 1
local ORT_MEM_TYPE_DEFAULT = 0
local ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT = 1
local CP_UTF8 = 65001
local NULL = ffi.cast("void*", 0)
local DLL_path = nil;

local Onnx = {
    available = false,
    runtime_version = nil,
    load_error = nil,
}

local state = {
    initialized = false,
    ort = nil, -- The loaded ONNX Runtime DLL object
    api_base = nil, -- The base API object for ONNX Runtime
    api = nil, -- The API object for ONNX Runtime
    env = nil, -- The ONNX Runtime environment object
    default_allocator = nil, -- The default memory allocator for ONNX Runtime
}


--- Checks whether an ONNX Runtime status handle is present and valid.
--- @param status any # Value returned by an ONNX Runtime API call.
--- @return boolean # True when the status is not nil and not NULL.
local function has_status(status)
    return status ~= nil and status ~= NULL
end


--- Raises an error if an ONNX Runtime call returned a failure status.
--- @param status any # Value returned by an ONNX Runtime API call.
--- @param action string # Human-readable description of the call that failed.
--- @return nil # Returns nothing when the status indicates success.
local function check(status, action)
    if not has_status(status) then
        return
    end

    if state.api == nil or type(state.api.GetErrorCode) ~= "function" or type(state.api.GetErrorMessage) ~= "function" then
        error(string.format("ONNX Runtime %s failed, but the API table is unavailable or incomplete", action), 2)
    end

    local err_code = tonumber(state.api.GetErrorCode(status)) or -1
    local err_ptr = state.api.GetErrorMessage(status)
    local err_msg = err_ptr ~= nil and ffi.string(err_ptr) or "Unknown ONNX Runtime error"
    error(string.format("ONNX Runtime %s failed (code %d): %s", action, err_code, err_msg), 2)
end


--- Converts a UTF-8 string to the UTF-16 buffer required by ONNX Runtime API calls.
--- @param text string # UTF-8 encoded string to convert.
--- @return userdata # UTF-16 wide-character buffer compatible with ONNX Runtime.
local function utf8_to_wide(text)
    local required_chars = ffi.C.MultiByteToWideChar(CP_UTF8, 0, text, -1, nil, 0)
    if required_chars == 0 then
        error("Failed to convert UTF-8 path to UTF-16 for ONNX Runtime", 2)
    end

    local wide = ffi.new("wchar_t[?]", required_chars)
    local written_chars = ffi.C.MultiByteToWideChar(CP_UTF8, 0, text, -1, wide, required_chars)
    if written_chars == 0 then
        error("Failed to write UTF-16 path for ONNX Runtime", 2)
    end

    return wide
end


--- Initializes the ONNX Runtime DLL and loads the API functions.
--- This function must be called before using any other ONNX Runtime functions.
--- @param runtime_path string|nil # The path to the ONNX Runtime DLL (optional, defaults to "misc/onnxruntime")
--- @return nil # Returns the ONNX Runtime API object if initialization is successful, otherwise nil
--- @return table # Returns state containing the initialization status and API references
function Onnx.init(runtime_path)
    DLL_path = runtime_path or "misc/onnxruntime"
    if state.initialized then -- already initialized
        return state.api, state
    end

    state.initialized = true

    local ok, ort_or_err = pcall(ffi.load, DLL_path)
    if not ok then
        state.load_error = "onnxruntime: Failed to load " .. DLL_path .. ".dll: " .. tostring(ort_or_err)
        print(state.load_error)
        Onnx.load_error = state.load_error
        return nil, state
    end

    print("Loaded '" .. DLL_path .. ".dll' library")

    state.ort = ort_or_err

    local api_base_ptr = state.ort.OrtGetApiBase()
    if api_base_ptr == nil or api_base_ptr == NULL then
        state.load_error = "onnxruntime: OrtGetApiBase returned NULL"
        Onnx.load_error = state.load_error
        return nil, state
    end

    state.api_base = api_base_ptr[0]

    local api_ptr = state.api_base.GetApi(ORT_API_VERSION)
    if api_ptr == nil or api_ptr == NULL then
        state.load_error = "onnxruntime: onnxruntime.dll does not support ORT_API_VERSION " .. ORT_API_VERSION
        Onnx.load_error = state.load_error
        return nil, state
    end

    state.api = api_ptr[0]
    Onnx.runtime_version = ffi.string(state.api_base.GetVersionString())
    Onnx.available = true

    print("ONNX Runtime initialized successfully, version: " .. Onnx.runtime_version)
    return state.api, state
end


--- Creates and caches the ONNX Runtime environment for future sessions.
--- @param log_id string|nil # Name used in the environment log output.
--- @param severity number|nil # Logging severity level for the environment.
--- @return userdata # Initialized ONNX Runtime environment handle.
function Onnx.create_env(log_id, severity)
    local api, err = Onnx.init()
    if not api then
        error(err, 2)
    end

    if state.env ~= nil and state.env[0] ~= nil and state.env[0] ~= NULL then
        return state.env[0]
    end

    local env_out = ffi.new("OrtEnv*[1]")
    check(api.CreateEnv(severity or ORT_LOGGING_LEVEL_WARNING, log_id or "Love2D", env_out),
        "CreateEnv")
    state.env = env_out

    print("ONNX Runtime environment created successfully")
    return env_out[0]
end


--- Creates an ONNX Runtime session for the specified model path.
--- @param model_path string # Path to the ONNX model file.
--- @return table # Session metadata containing the environment, options, handle, model path, and status message.
function Onnx.create_session(model_path)
    if type(model_path) ~= "string" or model_path == "" then
        error("ONNX model_path must be a non-empty string", 2)
    end

    local api, err = Onnx.init()
    if not api then
        error(err, 2)
    end

    local env = Onnx.create_env()

    -- setting session options
    local options_out = ffi.new("OrtSessionOptions*[1]")
    check(api.CreateSessionOptions(options_out), "CreateSessionOptions")
    check(api.DisableProfiling(options_out[0]), "DisableProfiling")
    check(api.SetSessionGraphOptimizationLevel(options_out[0],
        1), "SetSessionGraphOptimizationLevel") -- sets the graph optimization level to basic=1
    -- check(api.DisableMemPattern(options_out[0]), "DisableMemPattern") -- ?
    -- check(api.EnableMemPattern(options_out[0]), "EnableMemPattern")
    check(api.DisableCpuMemArena(options_out[0]), "DisableCpuMemArena") -- frees memory after session

    local session_out = ffi.new("OrtSession*[1]")
    local wide_model_path = utf8_to_wide(model_path)
    check(api.CreateSession(env, wide_model_path, options_out[0], session_out), "CreateSession")

    return {
        env = env,
        options = options_out[0],
        session = session_out[0],
        model_path = model_path,
        message = "ONNX Runtime session created successfully for model: `" .. model_path .. "`"
    }
end


--- Converts a Lua string into a NUL-terminated C string for FFI calls.
--- @param value string # Lua string to pass to the native API.
--- @return any # Null-terminated C string buffer.
local function to_c_string(value)
    local value_bytes = #value + 1
    local buf = ffi.new("char[?]", value_bytes)
    ffi.copy(buf, value)
    return buf
end


--- Returns the cached default allocator or creates it on first use.
--- @return userdata # Default ONNX Runtime allocator handle.
local function get_default_allocator()
    if state.default_allocator ~= nil and state.default_allocator[0] ~= nil and state.default_allocator[0] ~= NULL then
        return state.default_allocator[0]
    end

    local allocator_out = ffi.new("OrtAllocator*[1]")
    check(state.api.GetAllocatorWithDefaultOptions(allocator_out), "GetAllocatorWithDefaultOptions")
    state.default_allocator = allocator_out
    return allocator_out[0]
end


--- Reads the input or output tensor name for a specific session index.
--- @param session_ptr userdata|table # ONNX Runtime session handle.
--- @param index integer # Tensor index within the session.
--- @param is_input boolean # True to query an input name, false for an output name.
--- @return string # Tensor name.
local function get_session_name(session_ptr, index, is_input)
    local allocator = get_default_allocator()
    local name_out = ffi.new("char*[1]")

    if is_input then
        check(state.api.SessionGetInputName(session_ptr, index, allocator, name_out), "SessionGetInputName")
    else
        check(state.api.SessionGetOutputName(session_ptr, index, allocator, name_out), "SessionGetOutputName")
    end

    local name = ffi.string(name_out[0])
    check(state.api.AllocatorFree(allocator, name_out[0]), "AllocatorFree")
    return name
end


--- Collects the input and output tensor names from a session.
--- @param session_ptr userdata # ONNX Runtime session handle.
--- @return table # Input tensor names.
--- @return table # Output tensor names.
local function get_session_tensor_names(session_ptr)
    local input_count = ffi.new("size_t[1]")
    local output_count = ffi.new("size_t[1]")
    check(state.api.SessionGetInputCount(session_ptr, input_count), "SessionGetInputCount")
    check(state.api.SessionGetOutputCount(session_ptr, output_count), "SessionGetOutputCount")

    local input_names = {}
    for i = 0, tonumber(input_count[0]) - 1 do
        input_names[#input_names + 1] = get_session_name(session_ptr, i, true)
    end

    local output_names = {}
    for i = 0, tonumber(output_count[0]) - 1 do
        output_names[#output_names + 1] = get_session_name(session_ptr, i, false)
    end

    print("Input tensor names: " .. table.concat(input_names, ", "))
    print("Output tensor names: " .. table.concat(output_names, ", "))
    return input_names, output_names
end


--- Infers the model size expected by the input tensor.
--- @param input_shape table|nil # ONNX input shape list.
--- @return number # Width in pixels.
--- @return number # Height in pixels.
--- @return number # Channel count.
local function infer_model_input_size(input_shape)
    if type(input_shape) ~= "table" or #input_shape == 0 then
        print("Invalid input shape, using default size 320x320x3")
        return 320, 320, 3
    end

    local shape = {}
    for _, dim in ipairs(input_shape) do
        shape[#shape + 1] = tonumber(dim) or 0
    end

    local target_w = nil
    local target_h = nil
    local channel_count = 3

    if #shape >= 4 then
        if shape[1] == 1 and shape[2] > 0 then
            channel_count = shape[2]
            target_h = shape[3]
            target_w = shape[4]
        elseif shape[#shape] == 3 then
            target_h = shape[#shape - 2]
            target_w = shape[#shape - 1]
            channel_count = 3
        else
            target_h = shape[#shape - 1]
            target_w = shape[#shape]
        end
    elseif #shape >= 2 then
        target_h = shape[#shape - 1]
        target_w = shape[#shape]
    end

    if type(target_w) ~= "number" or type(target_h) ~= "number" or target_w <= 0 or target_h <= 0 then
        print("Invalid target width or height, using default size 320x320")
        return 320, 320, channel_count
    end

    print(string.format("Detected target size: %dx%d with %d channels", target_w, target_h, channel_count))
    return target_w, target_h, channel_count
end


--- Extracts tensor dimensions and the total element count from an OrtValue.
--- @param value userdata # Tensor value handle.
--- @return table # Tensor shape as a list of dimensions.
--- @return number # Total number of elements in the tensor.
local function get_value_shape(value)
    local shape_info_out = ffi.new("OrtTensorTypeAndShapeInfo*[1]")
    check(state.api.GetTensorTypeAndShape(value, shape_info_out), "GetTensorTypeAndShape")

    local dims_count_out = ffi.new("size_t[1]")
    check(state.api.GetDimensionsCount(shape_info_out[0], dims_count_out), "GetDimensionsCount")

    local dims_count = tonumber(dims_count_out[0])
    local dims = {}
    if dims_count > 0 then
        local dims_buffer = ffi.new("int64_t[?]", dims_count)
        check(state.api.GetDimensions(shape_info_out[0], dims_buffer, dims_count), "GetDimensions")
        for i = 0, dims_count - 1 do
            dims[#dims + 1] = tonumber(dims_buffer[i])
        end
    end

    local element_count_out = ffi.new("size_t[1]")
    check(state.api.GetTensorShapeElementCount(shape_info_out[0], element_count_out), "GetTensorShapeElementCount")
    print(string.format("Tensor element count: %d", tonumber(element_count_out[0]) or 0))
    return dims, tonumber(element_count_out[0]) or 0
end


--- Infers the mask width and height from a tensor shape.
--- @param dims table # Tensor dimension list.
--- @param element_count number # Number of elements in the tensor.
--- @return number # Mask width.
--- @return number # Mask height.
local function resolve_mask_dimensions(dims, element_count)
    if #dims >= 2 then
        local mask_h = dims[#dims - 1]
        local mask_w = dims[#dims]
        if mask_h ~= nil and mask_w ~= nil and mask_h > 0 and mask_w > 0 and mask_h * mask_w <= element_count then
            print(string.format("Using mask dimensions from tensor: %dx%d", mask_w, mask_h))
            return mask_w, mask_h
        end
    end

    local square_side = math.floor(math.sqrt(element_count))
    if square_side > 0 and square_side * square_side == element_count then
        print(string.format("Using square mask dimensions: %dx%d", square_side, square_side))
        return square_side, square_side
    end

    error("Unable to determine output mask dimensions from ONNX output tensor", 2)
end


--- Normalizes a raw mask value into the [0, 1] range.
--- @param mask_value number # Scalar value returned by the segmentation model.
--- @param min_value number # Minimum observed mask value.
--- @param max_value number # Maximum observed mask value.
--- @return number # Normalized alpha value in the [0, 1] range.
local function normalize_mask_value(mask_value, min_value, max_value)
    if max_value > min_value then
        return (mask_value - min_value) / (max_value - min_value)
    end

    return math.max(0.0, math.min(1.0, mask_value))
end


--- Resizes an image to the U2Net input size and applies standard RGB normalization.
--- @param image_data userdata # Love2D ImageData object.
--- @param target_w integer # Target width used by the U2Net model.
--- @param target_h integer # Target height used by the U2Net model.
--- @return any # Float buffer containing normalized RGB channels.
local function resize_and_normalize(image_data, target_w, target_h, channel_count)
    local src_w = image_data:getWidth()
    local src_h = image_data:getHeight()
    local float_buffer_size = target_w * target_h * channel_count
    local float_buffer = ffi.new("float[?]", float_buffer_size)
    local max_x = src_w - 1
    local max_y = src_h - 1
    local plane_size = target_w * target_h

    for y = 0, target_h - 1 do
        local src_y = math.min(max_y, math.floor((y + 0.5) * src_h / target_h))
        for x = 0, target_w - 1 do
            local src_x = math.min(max_x, math.floor((x + 0.5) * src_w / target_w))
            local r, g, b = image_data:getPixel(src_x, src_y)
            local pixel_index = y * target_w + x

            if channel_count >= 3 then
                float_buffer[pixel_index] = (r - 0.485) / 0.229
                float_buffer[plane_size + pixel_index] = (g - 0.456) / 0.224
                float_buffer[plane_size * 2 + pixel_index] = (b - 0.406) / 0.225
            else
                float_buffer[pixel_index] = r / 255.0
            end
        end
    end

    print("Float buffer size: " .. tostring(float_buffer_size) .. " bytes")
    return float_buffer
end


--- Reads the shape of a specific input tensor for the current ONNX session.
--- @param session_or_ptr userdata|table # ONNX session handle or session metadata table.
--- @param input_name string # Input tensor name to inspect.
--- @return table|nil # Input shape as a list of dimensions or nil if not found.
local function get_session_input_shape(session_or_ptr, input_name)
    local session_ptr = session_or_ptr
    if type(session_or_ptr) == "table" then
        if session_or_ptr.session == nil then
            print("Session metadata does not contain a valid session handle")
            return nil
        end
        session_ptr = session_or_ptr.session
    end

    if type(input_name) ~= "string" or input_name == "" then
        print("Invalid input name: " .. tostring(input_name))
        return nil
    end

    local input_count = ffi.new("size_t[1]")
    check(state.api.SessionGetInputCount(session_ptr, input_count), "SessionGetInputCount")

    for i = 0, tonumber(input_count[0]) - 1 do
        local name = get_session_name(session_ptr, i, true)
        if name == input_name then
            local type_info = ffi.new("OrtTypeInfo*[1]")
            check(state.api.SessionGetInputTypeInfo(session_ptr, i, type_info), "SessionGetInputTypeInfo")

            local tensor_info = ffi.new("const OrtTensorTypeAndShapeInfo*[1]")
            check(state.api.CastTypeInfoToTensorInfo(type_info[0], tensor_info), "CastTypeInfoToTensorInfo")

            local dims_count_out = ffi.new("size_t[1]")
            check(state.api.GetDimensionsCount(tensor_info[0], dims_count_out), "GetDimensionsCount")

            local dims_count = tonumber(dims_count_out[0])
            local dims = {}
            if dims_count > 0 then
                local dims_buffer = ffi.new("int64_t[?]", dims_count)
                check(state.api.GetDimensions(tensor_info[0], dims_buffer, dims_count), "GetDimensions")
                for idx = 0, dims_count - 1 do
                    dims[#dims + 1] = tonumber(dims_buffer[idx])
                end
            end

            if type_info[0] ~= nil and type_info[0] ~= NULL and state.api.ReleaseTypeInfo ~= nil then
                check(state.api.ReleaseTypeInfo(type_info[0]), "ReleaseTypeInfo")
            end
            -- if tensor_info[0] ~= nil and tensor_info[0] ~= NULL and state.api.ReleaseTensorTypeAndShapeInfo ~= nil then
            --     check(state.api.ReleaseTensorTypeAndShapeInfo(tensor_info[0]), "ReleaseTensorTypeAndShapeInfo") -- TODO
            -- end

            print(string.format("Detected input shape for tensor '%s': %s", input_name, table.concat(dims, "x")))
            return dims
        end
    end

    print("Input tensor not found: " .. tostring(input_name))
    return nil
end


--- Runs the segmentation model on an image and returns a new image with background removed.
--- @param session table # ONNX session metadata created by `Onnx.create_session`.
--- @param image_or_data love.Image|love.ImageData # Love2D Image or ImageData to process.
--- @param threshold number|nil # Threshold for background removal (default is 0.5).
--- @param return_image_data boolean|nil # When true, return an ImageData instead of a main-thread Image.
--- @return love.Image|love.ImageData # New asset with transparent background.
function Onnx.remove_background(session, image_or_data, threshold, return_image_data)
    threshold = threshold or 0.5
    return_image_data = return_image_data == true
    if type(session) ~= "table" or type(session.session) == "nil" then
        error("ONNX Runtime session is invalid", 2)
    end

    if type(image_or_data) ~= "userdata" then
        error("Expected a Love2D ImageData or Image object for background segmentation", 2)
    end

    local image_data = image_or_data
    if image_or_data.typeOf ~= nil and image_or_data:typeOf("Image") then
        image_data = image_or_data:getData()
    end

    local input_names, output_names = get_session_tensor_names(session.session)
    session.input_names = input_names
    session.output_names = output_names

    local input_name = input_names[1]
    local output_name = output_names[1]
    if input_name == nil or output_name == nil then
        error("ONNX Runtime session does not expose input/output tensor names", 2)
    end

    local shape = get_session_input_shape(session, input_name)
    local target_w, target_h, channel_count = infer_model_input_size(shape)
    if target_w <= 0 or target_h <= 0 then
        target_w, target_h, channel_count = 320, 320, 3
    end

    local src_w = image_data:getWidth()
    local src_h = image_data:getHeight()

    if channel_count < 1 then
        channel_count = 3
    end

    local input_buffer = resize_and_normalize(image_data, target_w, target_h, channel_count)
    local mem_info_out = ffi.new("OrtMemoryInfo*[1]")
    check(state.api.CreateCpuMemoryInfo(ORT_ARENA_ALLOCATOR, ORT_MEM_TYPE_DEFAULT, mem_info_out),
            "CreateCpuMemoryInfo")

    local shape_array = ffi.new("int64_t[4]", 1, channel_count, target_h, target_w)
    local input_value = ffi.new("OrtValue*[1]")
    local input_data_len = ffi.sizeof("float") * target_w * target_h * channel_count
    check(state.api.CreateTensorWithDataAsOrtValue(mem_info_out[0], ffi.cast("void*", input_buffer),
        input_data_len, shape_array, 4, ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT, input_value),
        "CreateTensorWithDataAsOrtValue")

    local input_name_cstr = to_c_string(input_name)
    local output_name_cstr = to_c_string(output_name)
    local input_name_ptr = ffi.new("const char*[1]", input_name_cstr)
    local output_name_ptr = ffi.new("const char*[1]", output_name_cstr)
    local input_tensors_ptr = ffi.new("const OrtValue*[1]", input_value[0])
    local output_tensors_ptr = ffi.new("OrtValue*[1]")
    output_tensors_ptr[0] = NULL

    check(state.api.Run(session.session, NULL, input_name_ptr, input_tensors_ptr, 1, output_name_ptr, 1,
        output_tensors_ptr), "Run")

    if output_tensors_ptr[0] == NULL then
        error("ONNX Runtime returned a NULL output tensor", 2)
    end

    local raw_output = ffi.new("void*[1]")
    check(state.api.GetTensorMutableData(output_tensors_ptr[0], raw_output), "GetTensorMutableData")

    local output_mask = ffi.cast("float*", raw_output[0])
    local output_dims, output_element_count = get_value_shape(output_tensors_ptr[0])
    local mask_w, mask_h = resolve_mask_dimensions(output_dims, output_element_count)

    local output_image_data = love.image.newImageData(src_w, src_h)

    local min_value = output_mask[0]
    local max_value = output_mask[0]
    for i = 1, mask_w * mask_h - 1 do
        local mask_value = output_mask[i]
        if mask_value < min_value then
            min_value = mask_value
        end
        if mask_value > max_value then
            max_value = mask_value
        end
    end
    print(string.format("Mask value range: min=%f, max=%f", min_value, max_value))

    for y = 0, src_h - 1 do
        local mask_y = math.min(mask_h - 1, math.floor((y + 0.5) * mask_h / src_h))
        for x = 0, src_w - 1 do
            local mask_x = math.min(mask_w - 1, math.floor((x + 0.5) * mask_w / src_w))
            local mask_index = mask_y * mask_w + mask_x
            local alpha = normalize_mask_value(output_mask[mask_index], min_value, max_value)

            local r, g, b, a = image_data:getPixel(x, y)
            local alpha_mask = alpha >= threshold and 1 or 0
            output_image_data:setPixel(x, y,
                r and alpha_mask == 1 and r or 0,
                g and alpha_mask == 1 and g or 0,
                b and alpha_mask == 1 and b or 0, alpha_mask)
        end
    end

    local r, g, b, a = output_image_data:getPixel(0, 0)
    print(string.format("Top-left pixel: R=%d, G=%d, B=%d, A=%d, alpha=%f",
            r * 255, g * 255, b * 255, a * 255, a))
    r, g, b, a = output_image_data:getPixel(src_w / 2 + 1, src_h / 2 + 1)
    print(string.format("Center pixel: R=%d, G=%d, B=%d, A=%d, alpha=%f",
            r * 255, g * 255, b * 255, a * 255, a))

    if input_value[0] ~= nil and input_value[0] ~= NULL and state.api.ReleaseValue ~= nil then
        check(state.api.ReleaseValue(input_value[0]), "ReleaseValue")
        input_value[0] = NULL
    else
        print("Input value was not released because it is nil or already NULL")
    end
    if output_tensors_ptr[0] ~= nil and output_tensors_ptr[0] ~= NULL and state.api.ReleaseValue ~= nil then
        check(state.api.ReleaseValue(output_tensors_ptr[0]), "ReleaseValue")
        output_tensors_ptr[0] = NULL
    else
        print("Output tensors pointer was not released because it is nil or already NULL")
    end
    -- if mem_info_out[0] ~= nil and mem_info_out[0] ~= NULL and state.api.ReleaseMemoryInfo ~= nil then
    --     state.api.ReleaseMemoryInfo(mem_info_out[0]) -- TODO: crash
    --     mem_info_out[0] = NULL
    -- else
    --     print("Memory info was not released because it is nil or already NULL")
    -- end
    -- if session.session ~= nil and session.session ~= NULL and state.api.ReleaseSession ~= nil then
    --     state.api.ReleaseSession(session.session) -- TODO: crash
    --     session.session = NULL
    -- else
    --     print("Session was not released because it is nil or already NULL or session.session is nil")
    -- end
    -- if state.api.ReleaseEnv ~= nil then
    --     state.api.ReleaseEnv(session.env) -- TODO: crash
    -- else
    --     print("Environment was not released because ReleaseEnv is nil")
    -- end

    if return_image_data then
        return output_image_data
    end

    return love.graphics.newImage(output_image_data)
end


return Onnx
