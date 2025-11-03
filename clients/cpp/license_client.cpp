/**
 * @file license_client.cpp
 * @brief Implementation of License Server Client Library for C++
 */

#include "license_client.hpp"
#include <curl/curl.h>
#include <json/json.h>
#include <sstream>

namespace license {

// Helper for CURL response handling
struct Response {
    std::string data;
    long http_code = 0;
};

static size_t write_callback(void* contents, size_t size, size_t nmemb, void* userp) {
    ((std::string*)userp)->append((char*)contents, size * nmemb);
    return size * nmemb;
}

// PIMPL implementation
class LicenseClient::Impl {
public:
    std::string base_url;
    CURL* curl;
    
    Impl(const std::string& url) : base_url(url) {
        curl_global_init(CURL_GLOBAL_DEFAULT);
        curl = curl_easy_init();
        if (!curl) {
            throw LicenseException("Failed to initialize CURL");
        }
    }
    
    ~Impl() {
        if (curl) {
            curl_easy_cleanup(curl);
        }
        curl_global_cleanup();
    }
    
    Response http_post(const std::string& endpoint, const std::string& json_data) {
        Response response;
        std::string url = base_url + endpoint;
        
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, json_data.c_str());
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response.data);
        
        struct curl_slist* headers = nullptr;
        headers = curl_slist_append(headers, "Content-Type: application/json");
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
        
        CURLcode res = curl_easy_perform(curl);
        curl_slist_free_all(headers);
        
        if (res != CURLE_OK) {
            throw LicenseException(std::string("CURL error: ") + curl_easy_strerror(res));
        }
        
        curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &response.http_code);
        return response;
    }
    
    Response http_get(const std::string& endpoint) {
        Response response;
        std::string url = base_url + endpoint;
        
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_HTTPGET, 1L);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response.data);
        
        CURLcode res = curl_easy_perform(curl);
        
        if (res != CURLE_OK) {
            throw LicenseException(std::string("CURL error: ") + curl_easy_strerror(res));
        }
        
        curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &response.http_code);
        return response;
    }
};

// LicenseHandle implementation
LicenseHandle::LicenseHandle(const std::string& id, const std::string& tool, 
                             const std::string& user)
    : id_(id), tool_(tool), user_(user), valid_(true) {}

LicenseHandle::~LicenseHandle() {
    if (valid_) {
        try {
            return_license();
        } catch (...) {
            // Suppress exceptions in destructor
        }
    }
}

LicenseHandle::LicenseHandle(LicenseHandle&& other) noexcept
    : id_(std::move(other.id_))
    , tool_(std::move(other.tool_))
    , user_(std::move(other.user_))
    , valid_(other.valid_) {
    other.valid_ = false;
}

LicenseHandle& LicenseHandle::operator=(LicenseHandle&& other) noexcept {
    if (this != &other) {
        if (valid_) {
            try {
                return_license();
            } catch (...) {}
        }
        id_ = std::move(other.id_);
        tool_ = std::move(other.tool_);
        user_ = std::move(other.user_);
        valid_ = other.valid_;
        other.valid_ = false;
    }
    return *this;
}

void LicenseHandle::return_license() {
    if (!valid_) return;
    
    // Note: This would need a reference to the client to actually return
    // For now, mark as invalid
    valid_ = false;
}

// LicenseClient implementation
LicenseClient::LicenseClient(const std::string& base_url)
    : pimpl_(std::make_unique<Impl>(base_url)) {}

LicenseClient::~LicenseClient() = default;

LicenseHandle LicenseClient::borrow(const std::string& tool, const std::string& user) {
    Json::Value request;
    request["tool"] = tool;
    request["user"] = user;
    
    Json::StreamWriterBuilder writer;
    std::string json_data = Json::writeString(writer, request);
    
    auto response = pimpl_->http_post("/licenses/borrow", json_data);
    
    if (response.http_code == 409) {
        throw NoLicensesAvailableException(tool);
    }
    
    if (response.http_code != 200) {
        throw LicenseException("HTTP error: " + std::to_string(response.http_code));
    }
    
    Json::Value json_response;
    Json::CharReaderBuilder reader;
    std::istringstream iss(response.data);
    std::string errs;
    
    if (!Json::parseFromStream(reader, iss, &json_response, &errs)) {
        throw LicenseException("Failed to parse response: " + errs);
    }
    
    std::string id = json_response["id"].asString();
    return LicenseHandle(id, tool, user);
}

void LicenseClient::return_license(const LicenseHandle& handle) {
    if (!handle.is_valid()) {
        throw LicenseException("Invalid license handle");
    }
    
    Json::Value request;
    request["id"] = handle.id();
    
    Json::StreamWriterBuilder writer;
    std::string json_data = Json::writeString(writer, request);
    
    auto response = pimpl_->http_post("/licenses/return", json_data);
    
    if (response.http_code != 200) {
        throw LicenseException("HTTP error: " + std::to_string(response.http_code));
    }
}

LicenseStatus LicenseClient::get_status(const std::string& tool) {
    auto response = pimpl_->http_get("/licenses/" + tool + "/status");
    
    if (response.http_code != 200) {
        throw LicenseException("HTTP error: " + std::to_string(response.http_code));
    }
    
    Json::Value json_response;
    Json::CharReaderBuilder reader;
    std::istringstream iss(response.data);
    std::string errs;
    
    if (!Json::parseFromStream(reader, iss, &json_response, &errs)) {
        throw LicenseException("Failed to parse response: " + errs);
    }
    
    LicenseStatus status;
    status.tool = json_response["tool"].asString();
    status.total = json_response["total"].asInt();
    status.borrowed = json_response["borrowed"].asInt();
    status.available = json_response["available"].asInt();
    status.commit = json_response.get("commit", 0).asInt();
    status.max_overage = json_response.get("max_overage", 0).asInt();
    status.overage = json_response.get("overage", 0).asInt();
    status.in_commit = json_response.get("in_commit", true).asBool();
    
    return status;
}

std::vector<LicenseStatus> LicenseClient::get_all_statuses() {
    auto response = pimpl_->http_get("/licenses/status");
    
    if (response.http_code != 200) {
        throw LicenseException("HTTP error: " + std::to_string(response.http_code));
    }
    
    Json::Value json_response;
    Json::CharReaderBuilder reader;
    std::istringstream iss(response.data);
    std::string errs;
    
    if (!Json::parseFromStream(reader, iss, &json_response, &errs)) {
        throw LicenseException("Failed to parse response: " + errs);
    }
    
    std::vector<LicenseStatus> statuses;
    for (const auto& item : json_response) {
        LicenseStatus status;
        status.tool = item["tool"].asString();
        status.total = item["total"].asInt();
        status.borrowed = item["borrowed"].asInt();
        status.available = item["available"].asInt();
        status.commit = item.get("commit", 0).asInt();
        status.max_overage = item.get("max_overage", 0).asInt();
        status.overage = item.get("overage", 0).asInt();
        status.in_commit = item.get("in_commit", true).asBool();
        statuses.push_back(status);
    }
    
    return statuses;
}

} // namespace license

