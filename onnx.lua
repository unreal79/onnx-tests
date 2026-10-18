
---@diagnostic disable: undefined-field

require("utils")
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
]])

local ORT_API_VERSION = 18 -- compatible with ONNX Runtime 1.14+
local ORT_LOGGING_LEVEL_WARNING = 2
local ORT_ARENA_ALLOCATOR = 1
local ORT_MEM_TYPE_DEFAULT = 0
local ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT = 1
local NULL = ffi.cast("void*", 0)

local Onnx = {
    available = false,
    runtime_version = nil,
    load_error = nil,
}

local State = {
    initialized = false,
    ort = nil, -- The loaded ONNX Runtime DLL object
    api_base = nil, -- The base API object for ONNX Runtime
    api = nil, -- The API object for ONNX Runtime
    env = nil, -- The ONNX Runtime environment object
    default_allocator = nil, -- The default memory allocator for ONNX Runtime
}


--- Raises an error if an ONNX Runtime call returned a failure status.
--- @param status any # Value returned by an ONNX Runtime API call.
--- @param action string # Human-readable description of the call that failed.
--- @return nil # Returns nothing when the status indicates success.
local function check(status, action)
    if status == nil or status == NULL then
        return
    end

    local err_code = tonumber(State.api.GetErrorCode(status)) or -1
    local err_ptr = State.api.GetErrorMessage(status)
    local err_msg = err_ptr ~= nil and ffi.string(err_ptr) or "Unknown ONNX Runtime error"
    error(string.format("ONNX Runtime %s failed (code %d): %s", action, err_code, err_msg), 2)
end


--- Initializes the ONNX Runtime DLL and loads the API functions.
--- This function must be called before using any other ONNX Runtime functions.
--- @param runtime_path string|nil # The path to the ONNX Runtime DLL (optional, defaults to "misc/onnxruntime")
--- @return nil # Returns the ONNX Runtime API object if initialization is successful, otherwise nil
--- @return table # Returns state containing the initialization status and API references
function Onnx.init(runtime_path)
    if State.initialized then -- already initialized
        return State.api, State
    end

    local ok, ort = pcall(ffi.load, runtime_path)
    if not ok then
        State.load_error = "onnxruntime: Failed to load " .. runtime_path .. ".dll"
        print(State.load_error)
        Onnx.load_error = State.load_error
        return nil, State
    end

    print("Loaded '" .. runtime_path .. ".dll' library")

    State.ort = ort

    local api_base_ptr = State.ort.OrtGetApiBase()
    if api_base_ptr == nil or api_base_ptr == NULL then
        State.load_error = "onnxruntime: OrtGetApiBase returned NULL"
        Onnx.load_error = State.load_error
        return nil, State
    end

    State.api_base = api_base_ptr[0]

    local api_ptr = State.api_base.GetApi(ORT_API_VERSION)
    if api_ptr == nil or api_ptr == NULL then
        State.load_error = "onnxruntime: onnxruntime.dll does not support ORT_API_VERSION " .. ORT_API_VERSION
        Onnx.load_error = State.load_error
        return nil, State
    end

    State.api = api_ptr[0]
    Onnx.runtime_version = ffi.string(State.api_base.GetVersionString())
    Onnx.available = true
    State.initialized = true

    print("ONNX Runtime initialized successfully, version: " .. Onnx.runtime_version)
    return State.api, State
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

    if State.env ~= nil and State.env[0] ~= nil and State.env[0] ~= NULL then
        return State.env[0]
    end

    local env_out = ffi.new("OrtEnv*[1]")
    check(api.CreateEnv(severity or ORT_LOGGING_LEVEL_WARNING, log_id or "Love2D", env_out),
        "CreateEnv")
    State.env = env_out

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


--- Reads the input or output tensor name for a specific session index.
--- @param session_ptr userdata|table # ONNX Runtime session handle.
--- @param index integer # Tensor index within the session.
--- @param is_input boolean # True to query an input name, false for an output name.
--- @return string # Tensor name.
local function get_session_name(session_ptr, index, is_input)
    local allocator = nil
    if State.default_allocator ~= nil and State.default_allocator[0] ~= nil and
            State.default_allocator[0] ~= NULL then
        allocator = State.default_allocator[0]
    else
        local allocator_out = ffi.new("OrtAllocator*[1]")
        check(State.api.GetAllocatorWithDefaultOptions(allocator_out), "GetAllocatorWithDefaultOptions")
        State.default_allocator = allocator_out
        allocator = allocator_out[0]
    end
    local name_out = ffi.new("char*[1]")

    if is_input then
        check(State.api.SessionGetInputName(session_ptr, index, allocator, name_out), "SessionGetInputName")
    else -- output names
        check(State.api.SessionGetOutputName(session_ptr, index, allocator, name_out), "SessionGetOutputName")
    end

    local name = ffi.string(name_out[0])
    check(State.api.AllocatorFree(allocator, name_out[0]), "AllocatorFree")
    return name
end


--- Infers the model size expected by the input tensor.
--- @param input_shape table|nil # ONNX input shape list.
--- @return number # Width in pixels.
--- @return number # Height in pixels.
--- @return number # Channel count.
local function infer_model_input_size(input_shape)
    local channel_count = 3
    if input_shape and #input_shape >= 3 then
        channel_count = tonumber(input_shape[2]) or 3
    else
        channel_count = 3
    end
    if type(input_shape) ~= "table" or #input_shape == 0 then
        local default_w_h = 512
        print("Invalid input shape, using default size " .. default_w_h .. "x" .. default_w_h ..
            "x" .. channel_count)
        return default_w_h, default_w_h, channel_count
    end

    local shape = {}
    for _, dim in ipairs(input_shape) do
        shape[#shape + 1] = tonumber(dim) or 0
    end

    local target_w = nil
    local target_h = nil

    if #shape >= 4 then
        if shape[1] == 1 and shape[2] > 0 then
            channel_count = shape[2]
            target_w = shape[4]
            target_h = shape[3]
            if channel_count > target_w and channel_count > 5 then
                target_w, channel_count = channel_count, target_w
                print(string.format("Swapped target_w and channel_count: target_w=%d, channel_count=%d",
                        target_w, channel_count))
            elseif channel_count > target_h and channel_count > 5 then
                target_h, channel_count = channel_count, target_h
                print(string.format("Swapped target_h and channel_count: target_h=%d, channel_count=%d",
                        target_h, channel_count))
            end
        elseif shape[#shape] == 3 then
            target_w = shape[#shape - 1]
            target_h = shape[#shape - 2]
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
        local default_w_h = 512
        print("Invalid target width or height, using default size " .. default_w_h .. "x" ..
            default_w_h .. " with " .. channel_count .. " channels")
        return default_w_h, default_w_h, channel_count
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
    check(State.api.GetTensorTypeAndShape(value, shape_info_out), "GetTensorTypeAndShape")

    local dims_count_out = ffi.new("size_t[1]")
    check(State.api.GetDimensionsCount(shape_info_out[0], dims_count_out), "GetDimensionsCount")

    local dims_count = tonumber(dims_count_out[0])
    local dims = {}
    if dims_count > 0 then
        local dims_buffer = ffi.new("int64_t[?]", dims_count)
        check(State.api.GetDimensions(shape_info_out[0], dims_buffer, dims_count), "GetDimensions")
        for i = 0, dims_count - 1 do
            dims[#dims + 1] = tonumber(dims_buffer[i])
        end
    end

    local element_count_out = ffi.new("size_t[1]")
    check(State.api.GetTensorShapeElementCount(shape_info_out[0], element_count_out), "GetTensorShapeElementCount")
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
        if mask_h ~= nil and mask_w ~= nil and mask_h > 0 and mask_w > 0 and
                mask_h * mask_w <= element_count then
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
--- @param image_data any # Love2D ImageData object.
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


--- Copies RGB data into a float buffer without ImageNet normalization.
--- @param image_data any # Love2D ImageData object.
--- @param target_w integer # Target width used by the model.
--- @param target_h integer # Target height used by the model.
--- @param channel_count integer # Number of channels expected by the model.
--- @return any # Float buffer containing planar RGB channels in the [0, 1] range.
local function resize_and_pack_rgb(image_data, target_w, target_h, channel_count)
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
                float_buffer[pixel_index] = r
                float_buffer[plane_size + pixel_index] = g
                float_buffer[plane_size * 2 + pixel_index] = b

                if channel_count > 3 then
                    for channel_index = 3, channel_count - 1 do
                        float_buffer[plane_size * channel_index + pixel_index] = 0
                    end
                end
            else
                float_buffer[pixel_index] = (r + g + b) / 3.0
            end
        end
    end

    print("RGB float buffer size: " .. tostring(float_buffer_size) .. " bytes")
    return float_buffer
end


--- Builds a single-channel inpainting mask from the source alpha channel.
--- Transparent pixels become holes to be filled by the inpainting model.
--- @param image_data any # Love2D ImageData object.
--- @param target_w integer # Target width used by the model.
--- @param target_h integer # Target height used by the model.
--- @param alpha_threshold number # Alpha threshold to determine transparent pixels.
--- @return table # Float buffer containing a binary mask in the [0, 1] range.
local function resize_and_pack_alpha_mask(image_data, target_w, target_h, alpha_threshold)
    local src_w = image_data:getWidth()
    local src_h = image_data:getHeight()
    local float_buffer_size = target_w * target_h
    local float_buffer = ffi.new("float[?]", float_buffer_size)
    local max_x = src_w - 1
    local max_y = src_h - 1

    for y = 0, target_h - 1 do
        local src_y = math.min(max_y, math.floor((y + 0.5) * src_h / target_h))
        for x = 0, target_w - 1 do
            local src_x = math.min(max_x, math.floor((x + 0.5) * src_w / target_w))
            local _, _, _, alpha = image_data:getPixel(src_x, src_y)
            local pixel_index = y * target_w + x
            float_buffer[pixel_index] = alpha < alpha_threshold and 1.0 or 0.0
        end
    end

    print("Mask float buffer size: " .. tostring(float_buffer_size) .. " bytes")
    return float_buffer
end


--- Ensures session tensor names are cached on the session metadata table.
--- @param session table # ONNX session metadata created by `Onnx.create_session`.
--- @return table # Input tensor names.
--- @return table # Output tensor names.
local function ensure_session_tensor_names(session)
    local input_names = session.input_names
    local output_names = session.output_names

    if type(input_names) ~= "table" or type(output_names) ~= "table" then
        local input_count = ffi.new("size_t[1]")
        local output_count = ffi.new("size_t[1]")
        check(State.api.SessionGetInputCount(session.session, input_count), "SessionGetInputCount")
        check(State.api.SessionGetOutputCount(session.session, output_count), "SessionGetOutputCount")

        input_names = {}
        for i = 0, tonumber(input_count[0]) - 1 do
            input_names[#input_names + 1] = get_session_name(session.session, i, true)
        end

        output_names = {}
        for i = 0, tonumber(output_count[0]) - 1 do
            output_names[#output_names + 1] = get_session_name(session.session, i, false)
        end

        print("Input tensor names: " .. table.concat(input_names, ", "))
        print("Output tensor names: " .. table.concat(output_names, ", "))
        session.input_names = input_names
        session.output_names = output_names
    end

    return input_names, output_names
end


--- Resolves the input size used for an inference call.
--- @param input_shape table|nil # ONNX input shape list.
--- @param fallback_w integer # Width to use when the model shape is dynamic.
--- @param fallback_h integer # Height to use when the model shape is dynamic.
--- @return number # Width used for the runtime input tensor.
--- @return number # Height used for the runtime input tensor.
--- @return number # Channel count.
local function resolve_runtime_input_size(input_shape, fallback_w, fallback_h)
    local target_w, target_h, channel_count = infer_model_input_size(input_shape)

    if type(input_shape) == "table" and #input_shape >= 4 then
        local width_dim = tonumber(input_shape[#input_shape]) or 0
        local height_dim = tonumber(input_shape[#input_shape - 1]) or 0
        if width_dim > 0 and height_dim > 0 then
            return target_w, target_h, math.max(1, channel_count)
        end
    end

    return fallback_w, fallback_h, math.max(1, channel_count)
end


--- Rounds a dimension up to the nearest multiple.
--- @param value integer # Source dimension.
--- @param multiple integer # Target multiple.
--- @return integer # Rounded dimension.
local function round_up_to_multiple(value, multiple)
    if multiple <= 1 then
        return math.max(1, value)
    end

    return math.max(multiple, math.floor((value + multiple - 1) / multiple) * multiple)
end


--- Resolves the runtime input size for the current colorizer model.
--- The manga colorizer expects `[1,5,H,W]` with height and width divisible by 32.
--- DeOldify ONNX models also require runtime dimensions divisible by 32.
--- @param input_shape table|nil # ONNX input shape list.
--- @param fallback_w integer # Source image width.
--- @param fallback_h integer # Source image height.
--- @return number # Runtime width.
--- @return number # Runtime height.
--- @return number # Runtime channel count.
local function resolve_colorizer_input_size(input_shape, fallback_w, fallback_h)
    local target_w, target_h, channel_count = infer_model_input_size(input_shape)

    if type(input_shape) == "table" and #input_shape >= 4 then
        local width_dim = tonumber(input_shape[#input_shape]) or 0
        local height_dim = tonumber(input_shape[#input_shape - 1]) or 0
        if width_dim > 0 and height_dim > 0 then
            return target_w, target_h, channel_count
        end
    end

    return round_up_to_multiple(fallback_w, 32), round_up_to_multiple(fallback_h, 32), channel_count
end


--- Runs a single-input single-output ONNX model and returns the output tensor.
--- @param session table # ONNX session metadata created by `Onnx.create_session`.
--- @param input_name string # Input tensor name.
--- @param output_name string # Output tensor name.
--- @param input_buffer any # Float tensor buffer.
--- @param input_w integer # Runtime input width.
--- @param input_h integer # Runtime input height.
--- @param channel_count integer # Runtime input channel count.
--- @return userdata # Input tensor handle.
--- @return userdata # Output tensor handle.
--- @return any # Float pointer to the output tensor memory.
--- @return table # Output tensor dimensions.
--- @return number # Output tensor element count.
local function run_single_output_session(session, input_name, output_name, input_buffer, input_w,
            input_h, channel_count)
    local mem_info_out = ffi.new("OrtMemoryInfo*[1]")
    check(State.api.CreateCpuMemoryInfo(ORT_ARENA_ALLOCATOR, ORT_MEM_TYPE_DEFAULT, mem_info_out),
        "CreateCpuMemoryInfo")

    local shape_array = ffi.new("int64_t[4]", 1, channel_count, input_h, input_w)
    local input_value = ffi.new("OrtValue*[1]")
    local input_data_len = ffi.sizeof("float") * input_w * input_h * channel_count
    check(State.api.CreateTensorWithDataAsOrtValue(mem_info_out[0], ffi.cast("void*", input_buffer),
        input_data_len, shape_array, 4, ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT, input_value),
        "CreateTensorWithDataAsOrtValue")

    local input_name_cstr = to_c_string(input_name)
    local output_name_cstr = to_c_string(output_name)
    local input_name_ptr = ffi.new("const char*[1]", input_name_cstr)
    local output_name_ptr = ffi.new("const char*[1]", output_name_cstr)
    local input_tensors_ptr = ffi.new("const OrtValue*[1]", input_value[0])
    local output_tensors_ptr = ffi.new("OrtValue*[1]")
    output_tensors_ptr[0] = NULL

    check(State.api.Run(session.session, NULL, input_name_ptr, input_tensors_ptr, 1, output_name_ptr, 1,
        output_tensors_ptr), "Run")

    if output_tensors_ptr[0] == NULL then
        error("ONNX Runtime returned a NULL output tensor", 2)
    end

    local raw_output = ffi.new("void*[1]")
    check(State.api.GetTensorMutableData(output_tensors_ptr[0], raw_output), "GetTensorMutableData")

    local output_dims, output_element_count = get_value_shape(output_tensors_ptr[0])
    return input_value[0], output_tensors_ptr[0], ffi.cast("float*", raw_output[0]), output_dims,
            output_element_count
end


--- Runs a two-input single-output ONNX inpainting model and returns the output tensor.
--- @param session table # ONNX session metadata created by `Onnx.create_session`.
--- @param image_input_name string # Image tensor input name.
--- @param mask_input_name string # Mask tensor input name.
--- @param output_name string # Output tensor name.
--- @param image_buffer any # Float image buffer in NCHW layout.
--- @param mask_buffer any # Float mask buffer in NCHW layout.
--- @param input_w integer # Runtime input width.
--- @param input_h integer # Runtime input height.
--- @return userdata # Image input tensor handle.
--- @return userdata # Mask input tensor handle.
--- @return userdata # Output tensor handle.
--- @return any # Float pointer to the output tensor memory.
--- @return table # Output tensor dimensions.
--- @return number # Output tensor element count.
local function run_inpaint_session(session, image_input_name, mask_input_name, output_name,
            image_buffer, mask_buffer, input_w, input_h)
    local mem_info_out = ffi.new("OrtMemoryInfo*[1]")
    check(State.api.CreateCpuMemoryInfo(ORT_ARENA_ALLOCATOR, ORT_MEM_TYPE_DEFAULT, mem_info_out),
        "CreateCpuMemoryInfo")

    local image_shape_array = ffi.new("int64_t[4]", 1, 3, input_h, input_w)
    local mask_shape_array = ffi.new("int64_t[4]", 1, 1, input_h, input_w)
    local image_input_value = ffi.new("OrtValue*[1]")
    local mask_input_value = ffi.new("OrtValue*[1]")

    local image_data_len = ffi.sizeof("float") * input_w * input_h * 3
    local mask_data_len = ffi.sizeof("float") * input_w * input_h
    check(State.api.CreateTensorWithDataAsOrtValue(mem_info_out[0], ffi.cast("void*", image_buffer),
        image_data_len, image_shape_array, 4, ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT, image_input_value),
        "CreateTensorWithDataAsOrtValue(image)")
    check(State.api.CreateTensorWithDataAsOrtValue(mem_info_out[0], ffi.cast("void*", mask_buffer),
        mask_data_len, mask_shape_array, 4, ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT, mask_input_value),
        "CreateTensorWithDataAsOrtValue(mask)")

    local image_input_name_cstr = to_c_string(image_input_name)
    local mask_input_name_cstr = to_c_string(mask_input_name)
    local output_name_cstr = to_c_string(output_name)
    local input_name_ptrs = ffi.new("const char*[2]", image_input_name_cstr, mask_input_name_cstr)
    local input_tensors_ptr = ffi.new("const OrtValue*[2]", image_input_value[0], mask_input_value[0])
    local output_name_ptr = ffi.new("const char*[1]", output_name_cstr)
    local output_tensors_ptr = ffi.new("OrtValue*[1]")
    output_tensors_ptr[0] = NULL

    check(State.api.Run(session.session, NULL, input_name_ptrs, input_tensors_ptr, 2, output_name_ptr, 1,
        output_tensors_ptr), "Run")

    if output_tensors_ptr[0] == NULL then
        error("ONNX Runtime returned a NULL output tensor", 2)
    end

    local raw_output = ffi.new("void*[1]")
    check(State.api.GetTensorMutableData(output_tensors_ptr[0], raw_output), "GetTensorMutableData")

    local output_dims, output_element_count = get_value_shape(output_tensors_ptr[0])
    return image_input_value[0], mask_input_value[0], output_tensors_ptr[0], ffi.cast("float*", raw_output[0]),
            output_dims, output_element_count
end


--- Packs a grayscale image for the current colorizer input tensor.
--- For the manga colorizer, ch0 = grayscale 0..1 and hint channels stay zeroed.
--- For DeOldify, grayscale is replicated into 3 RGB planes in the 0..255 range.
--- @param image_data any # Love2D ImageData object.
--- @param target_w integer # Runtime input width.
--- @param target_h integer # Runtime input height.
--- @param channel_count integer # Number of channels expected by the model.
--- @return any # Float buffer in NCHW layout.
local function resize_and_pack_colorizer_input(image_data, target_w, target_h, channel_count)
    local src_w = image_data:getWidth()
    local src_h = image_data:getHeight()
    local float_buffer_size = target_w * target_h * channel_count
    local float_buffer = ffi.new("float[?]", float_buffer_size)
    local max_x = src_w - 1
    local max_y = src_h - 1

    for y = 0, target_h - 1 do
        local src_y = math.min(max_y, math.floor((y + 0.5) * src_h / target_h))
        for x = 0, target_w - 1 do
            local src_x = math.min(max_x, math.floor((x + 0.5) * src_w / target_w))
            local r, g, b = image_data:getPixel(src_x, src_y)
            local pixel_index = y * target_w + x
            local grayscale = math.clamp((r * 0.299) + (g * 0.587) + (b * 0.114), 0, 1)

            if channel_count == 3 then
                local grayscale_255 = grayscale * 255.0
                local plane_size = target_w * target_h
                float_buffer[pixel_index] = grayscale_255
                float_buffer[plane_size + pixel_index] = grayscale_255
                float_buffer[(plane_size * 2) + pixel_index] = grayscale_255
            else
                float_buffer[pixel_index] = grayscale
            end
        end
    end

    print("Colorizer float buffer size: " .. tostring(float_buffer_size) .. " floats")
    return float_buffer
end


--- Resolves the tensor names used by the fixed-shape LaMa ONNX export.
--- @param input_names table # Input tensor names reported by the session.
--- @param output_names table # Output tensor names reported by the session.
--- @return string # Image input name.
--- @return string # Mask input name.
--- @return string # Output tensor name.
local function resolve_inpaint_tensor_names(input_names, output_names)
    local image_input_name = nil
    local mask_input_name = nil

    for _, name in ipairs(input_names) do
        if name == "image" then
            image_input_name = name
        elseif name == "mask" then
            mask_input_name = name
        end
    end

    image_input_name = image_input_name or input_names[1]
    mask_input_name = mask_input_name or input_names[2]
    local output_name = output_names[1]

    if image_input_name == nil or mask_input_name == nil or output_name == nil then
        error("ONNX Runtime inpainting session does not expose image/mask/output tensors", 2)
    end

    return image_input_name, mask_input_name, output_name
end


--- Releases an ONNX tensor handle if it is valid.
--- @param value userdata|nil # Tensor handle.
local function release_ort_value(value)
    if value ~= nil and value ~= NULL and State.api.ReleaseValue ~= nil then
        check(State.api.ReleaseValue(value), "ReleaseValue")
    end
end


--- Creates a new ImageData containing the selected region.
--- @param image_data any # Source ImageData.
--- @param start_x integer # Source X coordinate.
--- @param start_y integer # Source Y coordinate.
--- @param width integer # Region width.
--- @param height integer # Region height.
--- @return any # Cropped ImageData region.
local function copy_image_region(image_data, start_x, start_y, width, height)
    local region = love.image.newImageData(width, height)
    region:paste(image_data, 0, 0, start_x, start_y, width, height)
    return region
end


--- Builds tile start positions with guaranteed coverage of the source axis.
--- @param total_length integer # Source width or height.
--- @param tile_size integer # Tile size in pixels.
--- @param overlap integer # Overlap between adjacent tiles in pixels.
--- @return table # Ordered tile start coordinates.
local function build_tile_positions(total_length, tile_size, overlap)
    if total_length <= tile_size then
        return { 0 }
    end

    local positions = { 0 }
    local step = math.max(1, tile_size - overlap)
    local last_start = total_length - tile_size
    local position = 0

    while position < last_start do
        position = math.min(position + step, last_start)
        if position == positions[#positions] then
            break
        end
        positions[#positions + 1] = position
    end

    return positions
end


--- Computes the source interval owned by a tile after overlap splitting.
--- @param positions table # Tile start positions on an axis.
--- @param index integer # Current tile index.
--- @param total_length integer # Source width or height.
--- @param tile_size integer # Tile size in pixels.
--- @return number # Tile start.
--- @return number # Tile end.
--- @return number # Owned interval start.
--- @return number # Owned interval end.
local function resolve_tile_ownership(positions, index, total_length, tile_size)
    local tile_start = positions[index]
    local tile_extent = math.min(tile_size, total_length)
    local tile_end = math.min(total_length, tile_start + tile_extent)

    local owned_start = 0
    if index > 1 then
        local previous_start = positions[index - 1]
        local previous_end = math.min(total_length, previous_start + tile_extent)
        owned_start = math.floor(((tile_start + previous_end) * 0.5) + 0.5)
    end

    local owned_end = total_length
    if index < #positions then
        owned_end = math.floor(((positions[index + 1] + tile_end) * 0.5) + 0.5)
    end

    return tile_start, tile_end, owned_start, owned_end
end


--- Resolves a tensor layout into image dimensions.
--- @param dims table # Tensor dimension list.
--- @param element_count number # Number of elements in the tensor.
--- @return number # Image width.
--- @return number # Image height.
--- @return number # Channel count.
--- @return string # Tensor layout descriptor.
local function resolve_image_tensor_layout(dims, element_count)
    if #dims == 4 then
        if dims[1] == 1 and dims[2] > 0 and dims[2] <= 4 and dims[3] > 0 and dims[4] > 0 and
            dims[2] * dims[3] * dims[4] <= element_count then
            return dims[4], dims[3], dims[2], "nchw"
        end

        if dims[1] == 1 and dims[4] > 0 and dims[4] <= 4 and dims[2] > 0 and dims[3] > 0 and
            dims[2] * dims[3] * dims[4] <= element_count then
            return dims[3], dims[2], dims[4], "nhwc"
        end
    elseif #dims == 3 then
        if dims[1] > 0 and dims[1] <= 4 and dims[2] > 0 and dims[3] > 0 and
                dims[1] * dims[2] * dims[3] <= element_count then
            return dims[3], dims[2], dims[1], "nchw"
        end

        if dims[3] > 0 and dims[3] <= 4 and dims[1] > 0 and dims[2] > 0 and
                dims[1] * dims[2] * dims[3] <= element_count then
            return dims[2], dims[1], dims[3], "nhwc"
        end
    elseif #dims == 2 and dims[1] > 0 and dims[2] > 0 and dims[1] * dims[2] <= element_count then
        return dims[2], dims[1], 1, "hw"
    end

    error("Unsupported ONNX image tensor layout: " .. table.concat(dims, "x"), 2)
end


--- Reads an RGB pixel from an ONNX output tensor.
--- @param tensor_data any # Float pointer to tensor data.
--- @param layout string # Tensor layout descriptor.
--- @param channel_count integer # Number of tensor channels.
--- @param image_w integer # Tensor image width.
--- @param image_h integer # Tensor image height.
--- @param x integer # Pixel X coordinate.
--- @param y integer # Pixel Y coordinate.
--- @return number # Red channel.
--- @return number # Green channel.
--- @return number # Blue channel.
local function read_tensor_rgb(tensor_data, layout, channel_count, image_w, image_h, x, y)
    local pixel_index = y * image_w + x
    if layout == "nchw" then
        local plane_size = image_w * image_h
        local r = tensor_data[pixel_index]
        local g = channel_count >= 2 and tensor_data[plane_size + pixel_index] or r
        local b = channel_count >= 3 and tensor_data[(plane_size * 2) + pixel_index] or g
        return r, g, b
    end

    if layout == "nhwc" then
        local base_index = (pixel_index * channel_count)
        local r = tensor_data[base_index]
        local g = channel_count >= 2 and tensor_data[base_index + 1] or r
        local b = channel_count >= 3 and tensor_data[base_index + 2] or g
        return r, g, b
    end

    local value = tensor_data[pixel_index]
    return value, value, value
end


--- Detects the output value scale used by a super-resolution model.
--- @param tensor_data any # Float pointer to tensor data.
--- @param element_count number # Number of tensor elements.
--- @return number # Multiplier applied before clamping to [0, 1].
local function detect_output_value_scale(tensor_data, element_count)
    local min_value = tensor_data[0]
    local max_value = tensor_data[0]
    local sample_step = math.max(1, math.floor(element_count / 4096))

    for index = sample_step, element_count - 1, sample_step do
        local value = tensor_data[index]
        if value < min_value then
            min_value = value
        end
        if value > max_value then
            max_value = value
        end
    end

    print(string.format("Upscale output range: min=%f, max=%f", min_value, max_value))
    if max_value > 2.0 or min_value < -0.5 then
        return 1.0 / 255.0
    end

    return 1.0
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
    check(State.api.SessionGetInputCount(session_ptr, input_count), "SessionGetInputCount")

    for i = 0, tonumber(input_count[0]) - 1 do
        local name = get_session_name(session_ptr, i, true)
        if name == input_name then
            local type_info = ffi.new("OrtTypeInfo*[1]")
            check(State.api.SessionGetInputTypeInfo(session_ptr, i, type_info), "SessionGetInputTypeInfo")

            local tensor_info = ffi.new("const OrtTensorTypeAndShapeInfo*[1]")
            check(State.api.CastTypeInfoToTensorInfo(type_info[0], tensor_info), "CastTypeInfoToTensorInfo")

            local dims_count_out = ffi.new("size_t[1]")
            check(State.api.GetDimensionsCount(tensor_info[0], dims_count_out), "GetDimensionsCount")

            local dims_count = tonumber(dims_count_out[0])
            local dims = {}
            if dims_count > 0 then
                local dims_buffer = ffi.new("int64_t[?]", dims_count)
                check(State.api.GetDimensions(tensor_info[0], dims_buffer, dims_count), "GetDimensions")
                for idx = 0, dims_count - 1 do
                    dims[#dims + 1] = tonumber(dims_buffer[idx])
                end
            end

            if type_info[0] ~= nil and type_info[0] ~= NULL and State.api.ReleaseTypeInfo ~= nil then
                check(State.api.ReleaseTypeInfo(type_info[0]), "ReleaseTypeInfo")
            end
            -- if tensor_info[0] ~= nil and tensor_info[0] ~= NULL and state.api.ReleaseTensorTypeAndShapeInfo ~= nil then
            --     check(state.api.ReleaseTensorTypeAndShapeInfo(tensor_info[0]), "ReleaseTensorTypeAndShapeInfo") -- TODO
            -- end

            print(string.format("Detected input shape for tensor '%s': %s", input_name,
                    table.concat(dims, "x")))
            return dims
        end
    end

    print("Input tensor not found: " .. tostring(input_name))
    return nil
end


--- Runs the segmentation model on an image and returns a new image with background removed.
--- @param session table # ONNX session metadata created by `Onnx.create_session`.
--- @param image_or_data love.Image|love.ImageData # Love2D Image or ImageData to process.
--- @param alpha_threshold number|nil # Threshold for background removal (default is 0.5).
--- @param return_image_data boolean|nil # When true, return an ImageData instead of a main-thread Image.
--- @return love.Image|love.ImageData # New asset with transparent background.
function Onnx.remove_background(session, image_or_data, alpha_threshold, return_image_data)
    alpha_threshold = alpha_threshold or 0.5
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

    local input_names, output_names = ensure_session_tensor_names(session)

    local input_name = input_names[1]
    local output_name = output_names[1]
    if input_name == nil or output_name == nil then
        error("ONNX Runtime session does not expose input/output tensor names", 2)
    end

    local shape = get_session_input_shape(session, input_name)
    local target_w, target_h, channel_count = infer_model_input_size(shape)

    local src_w = image_data:getWidth()
    local src_h = image_data:getHeight()

    if channel_count < 1 then
        channel_count = 3
    end

    local input_buffer = resize_and_normalize(image_data, target_w, target_h, channel_count)
    local input_value, output_value, output_mask, output_dims, output_element_count = run_single_output_session(
            session, input_name, output_name, input_buffer, target_w, target_h, channel_count)
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
            local alpha_mask = alpha >= alpha_threshold and 1 or 0
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

    release_ort_value(input_value)
    release_ort_value(output_value)
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


--- Runs the LaMa inpainting model using the source alpha channel as the hole mask.
--- @param session table # ONNX session metadata created by `Onnx.create_session`.
--- @param image_or_data love.Image|love.ImageData # Love2D Image or ImageData to inpaint.
--- @param alpha_threshold number|nil # Alpha threshold to determine transparent pixels in the hole mask. Defaults to `INPAINTER_ALPHA_THRESHOLD` if not provided.
--- @param return_image_data boolean|nil # When true, return an ImageData instead of a main-thread Image.
--- @return love.Image|love.ImageData # Inpainted image with opaque filled regions.
function Onnx.inpaint(session, image_or_data, alpha_threshold, return_image_data)
    alpha_threshold = alpha_threshold or 0.5
    return_image_data = return_image_data == true
    if type(session) ~= "table" or type(session.session) == "nil" then
        error("ONNX Runtime session is invalid", 2)
    end

    if type(image_or_data) ~= "userdata" then
        error("Expected a Love2D ImageData or Image object for image inpainting", 2)
    end

    local image_data = image_or_data
    if image_or_data.typeOf ~= nil and image_or_data:typeOf("Image") then
        image_data = image_or_data:getData()
    end

    local input_names, output_names = ensure_session_tensor_names(session)
    local image_input_name, mask_input_name, output_name = resolve_inpaint_tensor_names(input_names, output_names)

    local src_w = image_data:getWidth()
    local src_h = image_data:getHeight()
    local shape = get_session_input_shape(session, image_input_name)
    local input_w, input_h, channel_count = infer_model_input_size(shape)

    local image_input_buffer = resize_and_pack_rgb(image_data, input_w, input_h, 3)
    local mask_input_buffer = resize_and_pack_alpha_mask(image_data, input_w, input_h, alpha_threshold)
    local image_input_value, mask_input_value, output_value, raw_output, output_dims, output_element_count =
            run_inpaint_session(session, image_input_name, mask_input_name, output_name, image_input_buffer,
                mask_input_buffer, input_w, input_h)

    local out_w, out_h, output_channels, output_layout = resolve_image_tensor_layout(output_dims,
            output_element_count)
    local output_value_scale = detect_output_value_scale(raw_output, output_element_count)
    local output_image_data = love.image.newImageData(src_w, src_h)

    print(string.format("Inpaint output size: %dx%d", out_w, out_h))

    for y = 0, src_h - 1 do
        local sample_y = math.min(out_h - 1, math.floor((y + 0.5) * out_h / src_h))
        for x = 0, src_w - 1 do
            local sample_x = math.min(out_w - 1, math.floor((x + 0.5) * out_w / src_w))
            local source_r, source_g, source_b, source_a = image_data:getPixel(x, y)

            if source_a < 0.5 then
                local fill_r, fill_g, fill_b = read_tensor_rgb(raw_output, output_layout, output_channels,
                    out_w, out_h, sample_x, sample_y)
                output_image_data:setPixel(x, y,
                    math.clamp(fill_r * output_value_scale, 0, 1),
                    math.clamp(fill_g * output_value_scale, 0, 1),
                    math.clamp(fill_b * output_value_scale, 0, 1),
                    1)
            else
                output_image_data:setPixel(x, y, source_r, source_g, source_b, 1)
            end
        end
    end

    release_ort_value(image_input_value)
    release_ort_value(mask_input_value)
    release_ort_value(output_value)

    if return_image_data then
        return output_image_data
    end

    return love.graphics.newImage(output_image_data)
end


--- Runs the manga colorizer model on a grayscale image.
--- @param session table # ONNX session metadata created by `Onnx.create_session`.
--- @param image_or_data love.Image|love.ImageData # Love2D Image or ImageData to colorize.
--- @param return_image_data boolean|nil # When true, return an ImageData instead of a main-thread Image.
--- @return love.Image|love.ImageData # Colorized image.
function Onnx.colorize(session, image_or_data, return_image_data)
    return_image_data = return_image_data == true
    if type(session) ~= "table" or type(session.session) == "nil" then
        error("ONNX Runtime session is invalid", 2)
    end

    if type(image_or_data) ~= "userdata" then
        error("Expected a Love2D ImageData or Image object for image colorization", 2)
    end

    local image_data = image_or_data
    if image_or_data.typeOf ~= nil and image_or_data:typeOf("Image") then
        image_data = image_or_data:getData()
    end

    local input_names, output_names = ensure_session_tensor_names(session)
    local input_name = input_names[1]
    local output_name = output_names[1]
    if input_name == nil or output_name == nil then
        error("ONNX Runtime session does not expose input/output tensor names", 2)
    end

    local src_w = image_data:getWidth()
    local src_h = image_data:getHeight()
    local input_shape = get_session_input_shape(session, input_name)
    local input_w, input_h, channel_count = resolve_colorizer_input_size(input_shape, src_w, src_h)
    local is_deoldify_model = channel_count == 3 -- detected DeOldify models with 3-channel input (RGB)
    local input_buffer = resize_and_pack_colorizer_input(image_data, input_w, input_h, channel_count)
    local input_value, output_value, raw_output, output_dims, output_element_count = run_single_output_session(
            session, input_name, output_name, input_buffer, input_w, input_h, channel_count)

    local out_w, out_h, output_channels, output_layout = resolve_image_tensor_layout(output_dims,
            output_element_count)
    local output_value_scale = is_deoldify_model and detect_output_value_scale(raw_output,
            output_element_count) or 1.0
    local output_image_data = love.image.newImageData(src_w, src_h)

    print(string.format("Colorize output size: %dx%d", out_w, out_h))

    for y = 0, src_h - 1 do
        local sample_y = math.min(out_h - 1, math.floor((y + 0.5) * out_h / src_h))
        for x = 0, src_w - 1 do
            local sample_x = math.min(out_w - 1, math.floor((x + 0.5) * out_w / src_w))
            local r, g, b = read_tensor_rgb(raw_output, output_layout, output_channels, out_w, out_h,
                    sample_x, sample_y)
            r = math.clamp(r * output_value_scale, 0, 1)
            g = math.clamp(g * output_value_scale, 0, 1)
            b = math.clamp(b * output_value_scale, 0, 1)

            if is_deoldify_model then
                local source_r, source_g, source_b = image_data:getPixel(x, y)
                local source_luma = math.clamp((source_r * 0.299) + (source_g * 0.587) + (source_b * 0.114), 0, 1)
                local color_luma = (r * 0.299) + (g * 0.587) + (b * 0.114)
                if color_luma > 0.0001 then
                    local luma_scale = source_luma / color_luma
                    r = math.clamp(r * luma_scale, 0, 1)
                    g = math.clamp(g * luma_scale, 0, 1)
                    b = math.clamp(b * luma_scale, 0, 1)
                else
                    r, g, b = source_luma, source_luma, source_luma
                end
            end

            output_image_data:setPixel(x, y, r, g, b, 1)
        end
    end

    release_ort_value(input_value)
    release_ort_value(output_value)

    if return_image_data then
        return output_image_data
    end

    return love.graphics.newImage(output_image_data)
end


--- Runs the super-resolution model over an image using overlapped 256x256 tiles.
--- @param session table # ONNX session metadata created by `Onnx.create_session`.
--- @param image_or_data love.Image|love.ImageData # Love2D Image or ImageData to upscale.
--- @param return_image_data boolean|nil # When true, return an ImageData instead of a main-thread Image.
--- @param tile_size number|nil # The size of the tiles to use for upscaling. Defaults to 256.
--- @param tile_overlap number|nil # The overlap between tiles. Defaults to 32.
--- @return love.Image|love.ImageData # Upscaled image assembled from model tiles.
function Onnx.upscale(session, image_or_data, return_image_data, tile_size, tile_overlap)
    return_image_data = return_image_data == true
    tile_size = tile_size or 256
    tile_overlap = tile_overlap or 32
    if type(session) ~= "table" or type(session.session) == "nil" then
        error("ONNX Runtime session is invalid", 2)
    end

    if type(image_or_data) ~= "userdata" then
        error("Expected a Love2D ImageData or Image object for image upscaling", 2)
    end

    local image_data = image_or_data
    if image_or_data.typeOf ~= nil and image_or_data:typeOf("Image") then
        image_data = image_or_data:getData()
    end

    local input_names, output_names = ensure_session_tensor_names(session)
    local input_name = input_names[1]
    local output_name = output_names[1]
    if input_name == nil or output_name == nil then
        error("ONNX Runtime session does not expose input/output tensor names", 2)
    end

    local input_shape = get_session_input_shape(session, input_name)
    local src_w = image_data:getWidth()
    local src_h = image_data:getHeight()
    local x_positions = build_tile_positions(src_w, tile_size, tile_overlap)
    local y_positions = build_tile_positions(src_h, tile_size, tile_overlap)

    local runtime_input_w, runtime_input_h, channel_count = resolve_runtime_input_size(input_shape,
            math.min(tile_size, src_w), math.min(tile_size, src_h))
    if channel_count < 1 then
        channel_count = 3
    end

    local output_image_data = nil
    local scale_x = nil
    local scale_y = nil
    local output_value_scale = nil

    for tile_y_index, tile_y in ipairs(y_positions) do
        local _, tile_src_end_y, owned_src_top, owned_src_bottom = resolve_tile_ownership(y_positions,
                tile_y_index, src_h, tile_size)
        local tile_h = tile_src_end_y - tile_y
        local owned_tile_top = owned_src_top - tile_y

        for tile_x_index, tile_x in ipairs(x_positions) do
            print(string.format("Processing tile %d out of %d",
                    (tile_y_index - 1) * #x_positions + tile_x_index, #x_positions * #y_positions))
            local _, tile_src_end_x, owned_src_left, owned_src_right = resolve_tile_ownership(x_positions,
                    tile_x_index, src_w, tile_size)
            local tile_w = tile_src_end_x - tile_x
            local owned_tile_left = owned_src_left - tile_x

            local tile_image_data = copy_image_region(image_data, tile_x, tile_y, tile_w, tile_h)
            local tile_input_buffer = resize_and_pack_rgb(tile_image_data, runtime_input_w, runtime_input_h,
                    channel_count)
            local input_value, output_value, raw_output, output_dims, output_element_count =
                run_single_output_session(session, input_name, output_name, tile_input_buffer, runtime_input_w,
                        runtime_input_h, channel_count)

            local tile_out_w, tile_out_h, output_channels, output_layout = resolve_image_tensor_layout(output_dims,
                    output_element_count)

            if scale_x == nil or scale_y == nil then
                scale_x = tile_out_w / tile_w
                scale_y = tile_out_h / tile_h
                if scale_x <= 0 or scale_y <= 0 then
                    release_ort_value(input_value)
                    release_ort_value(output_value)
                    error("Upscale model returned invalid output dimensions", 2)
                end

                output_image_data = love.image.newImageData(
                    math.max(1, math.floor((src_w * scale_x) + 0.5)),
                    math.max(1, math.floor((src_h * scale_y) + 0.5))
                )
                output_value_scale = detect_output_value_scale(raw_output, output_element_count)
                print(string.format("Detected upscale factor: %.4fx%.4f", scale_x, scale_y))
                print(string.format("Upscaled image size: %dx%d", output_image_data:getWidth(),
                    output_image_data:getHeight()))
            end

            if output_image_data == nil or output_value_scale == nil then
                release_ort_value(input_value)
                release_ort_value(output_value)
                error("Upscale output buffer was not initialized", 2)
            end

            local dst_x = math.floor((owned_src_left * scale_x) + 0.5)
            local dst_y = math.floor((owned_src_top * scale_y) + 0.5)
            local crop_out_x = math.floor((owned_tile_left * scale_x) + 0.5)
            local crop_out_y = math.floor((owned_tile_top * scale_y) + 0.5)
            local crop_out_w = math.max(1, math.floor(((owned_src_right - owned_src_left) * scale_x) + 0.5))
            local crop_out_h = math.max(1, math.floor(((owned_src_bottom - owned_src_top) * scale_y) + 0.5))

            crop_out_w = math.min(crop_out_w, tile_out_w - crop_out_x)
            crop_out_h = math.min(crop_out_h, tile_out_h - crop_out_y)
            crop_out_w = math.min(crop_out_w, output_image_data:getWidth() - dst_x)
            crop_out_h = math.min(crop_out_h, output_image_data:getHeight() - dst_y)

            for out_y = 0, crop_out_h - 1 do
                for out_x = 0, crop_out_w - 1 do
                    local r, g, b = read_tensor_rgb(raw_output, output_layout, output_channels,
                        tile_out_w, tile_out_h, crop_out_x + out_x, crop_out_y + out_y)
                    output_image_data:setPixel(dst_x + out_x, dst_y + out_y,
                        math.clamp(r * output_value_scale, 0, 1),
                        math.clamp(g * output_value_scale, 0, 1),
                        math.clamp(b * output_value_scale, 0, 1),
                        1)
                end
            end

            release_ort_value(input_value)
            release_ort_value(output_value)
        end
    end
    print(string.format("Final output image size: %dx%d", output_image_data:getWidth(), output_image_data:getHeight()))

    if output_image_data == nil then
        error("Upscale did not produce any output tiles", 2)
    end

    if return_image_data then
        return output_image_data
    end

    return love.graphics.newImage(output_image_data)
end


return Onnx
