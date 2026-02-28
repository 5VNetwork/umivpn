#include "windows_host_api.h"
#include "utils.h"
#include <ip2string.h>
#include <in6addr.h>
#include <fwpmu.h>
#include "guid.h"


namespace x
{
    MessageFlutterApi*  message_api = nullptr;

    WindowsHostApiImpl::WindowsHostApiImpl()
    {
        _disableDefaultDns = std::make_unique<DisableDefaultDns>();
    }
    WindowsHostApiImpl::~WindowsHostApiImpl()
    {
    }

    ErrorOr<bool> WindowsHostApiImpl::IsRunningAsAdmin() {
        BOOL isAdmin = FALSE;
        HANDLE hToken = NULL;

        if (OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &hToken)) {
            TOKEN_ELEVATION elevation;
            DWORD size = sizeof(TOKEN_ELEVATION);

            if (GetTokenInformation(hToken, TokenElevation, &elevation, sizeof(elevation), &size)) {
                isAdmin = elevation.TokenIsElevated;
            }

            CloseHandle(hToken);
        }

        return isAdmin;
    }

    std::optional<FlutterError> WindowsHostApiImpl::DisableDNS(int64_t index)
    {
        try
        {
            _disableDefaultDns->Do(index);
        }
        catch (const std::runtime_error &e)
        {
            return FlutterError(e.what());
        }
        return {};
    }   

    std::optional<FlutterError> WindowsHostApiImpl::UndoDisableDNS()
    {
        try
        {
            _disableDefaultDns->Undo();
        }
        catch (const std::runtime_error &e)
        {
            return FlutterError(e.what());
        }
        return {};
    }

    HANDLE _addSession(
        wchar_t *sessionName,
        wchar_t *providerName,
        wchar_t *sublayerName,
        const GUID *providerKey,
        const GUID *sublayerKey)
    {
        HANDLE engine = NULL;
        std::string error = "";
        DWORD result = ERROR_SUCCESS;
        FWPM_SESSION0 session;
        FWPM_PROVIDER0 provider;
        FWPM_SUBLAYER0 subLayer;

        memset(&session, 0, sizeof(session));
        session.displayData.name = sessionName;
        session.txnWaitTimeoutInMSec = INFINITE;
        session.flags = FWPM_SESSION_FLAG_DYNAMIC;

        result = FwpmEngineOpen0(
            NULL,
            RPC_C_AUTHN_DEFAULT,
            NULL,
            &session,
            &engine);
        EXIT_ON_ERROR(FwpmEngineOpen0);

        result = FwpmTransactionBegin0(engine, 0);
        EXIT_ON_ERROR(FwpmTransactionBegin0);

        memset(&provider, 0, sizeof(provider));
        provider.providerKey = *providerKey;
        provider.displayData.name = providerName;
        result = FwpmProviderAdd0(engine, &provider, NULL);
        if (result != FWP_E_ALREADY_EXISTS)
        {
            EXIT_ON_ERROR(FwpmProviderAdd0);
        }

        memset(&subLayer, 0, sizeof(subLayer));
        subLayer.subLayerKey = *sublayerKey;
        subLayer.displayData.name = sublayerName;
        subLayer.providerKey = (GUID *)providerKey;
        subLayer.weight = FWP_EMPTY;
        result = FwpmSubLayerAdd0(engine, &subLayer, NULL);
        if (result != FWP_E_ALREADY_EXISTS)
        {
            EXIT_ON_ERROR(FwpmSubLayerAdd0);
        }

        result = FwpmTransactionCommit0(engine);
        EXIT_ON_ERROR(FwpmTransactionCommit0);

    CLEANUP:
        if (error.length() > 0)
        {
            throw std::runtime_error(error);
        }
        return engine;
    }

    void WindowsHostApiImpl::_uninstallProvider()
    {
        DWORD result = ERROR_SUCCESS;
        std::string error = "";
        if (_engine == NULL)
        {
            return;
        }

        // We delete the provider and sublayer from within a single transaction, so
        // that we always leave the system in a consistent state even in error
        // paths.
        result = FwpmTransactionBegin0(_engine, 0);
        EXIT_ON_ERROR(FwpmTransactionBegin0);

        // We have to delete the sublayer first since it references the provider. If
        // we tried to delete the provider first, it would fail with FWP_E_IN_USE.
        result = FwpmSubLayerDeleteByKey0(_engine, &SUBLAYER_KEY);
        if (result != FWP_E_SUBLAYER_NOT_FOUND)
        {
            // Ignore FWP_E_SUBLAYER_NOT_FOUND. This allows uninstall to succeed even
            // if the current configuration is broken.
            EXIT_ON_ERROR(FwpmSubLayerDeleteByKey0);
        }

        result = FwpmProviderDeleteByKey0(_engine, &PROVIDER_KEY);
        if (result != FWP_E_PROVIDER_NOT_FOUND)
        {
            EXIT_ON_ERROR(FwpmProviderDeleteByKey0);
        }

        // Once all the deletes have succeeded, we commit the transaction to
        // atomically delete all the objects.
        result = FwpmTransactionCommit0(_engine);
        EXIT_ON_ERROR(FwpmTransactionCommit0);

    CLEANUP:
        // FwpmEngineClose0 accepts null engine handles, so we needn't precheck for
        // null. Also, when closing an engine handle, any transactions still in
        // progress are automatically aborted, so we needn't explicitly abort the
        // transaction in error paths.
        FwpmEngineClose0(_engine);
        return;
    }
    
    DisableDefaultDns::DisableDefaultDns()
    {
    }
    DisableDefaultDns::~DisableDefaultDns()
    {
    }
    // All ordinary(UDP, 53) dns requests that are not from the current process and destined for the
    // interfaces other than [index] will be blocked.
    void DisableDefaultDns::Do(int64_t index)
    {
        if (_engine != NULL)
        {
            FwpmEngineClose0(_engine);
        }

        _engine = _addSession((wchar_t*)L"UmiVPN Disable Default DNS Provider Session",
                              (wchar_t*)L"UmiVPN Disable Default DNS Provider", 
                              (wchar_t*)L"UmiVPN Disable Default DNS Sublayer",
                              &PROVIDER_KEY,
                              &SUBLAYER_KEY);

        DWORD result = ERROR_SUCCESS;
        FWPM_FILTER0 filter = {0};
        FWPM_FILTER_CONDITION conds[3] = {0};
        std::string error = "";
        FWP_BYTE_BLOB *appBlob = NULL;

        // print
        printf("GetCurrentProcessAppId\n");

        std::wstring appId = GetCurrentProcessAppId();
        result = FwpmGetAppIdFromFileName0(appId.c_str(), &appBlob);

        printf("App ID path: %ls\n", appId.c_str());

        filter.displayData.name = (wchar_t *)L"umivpn block default dns nameserver";
        filter.displayData.description = (wchar_t *)L"umivpn block default dns nameserver";
        filter.action.type = FWP_ACTION_BLOCK;
        filter.providerKey = (GUID *)&PROVIDER_KEY;
        filter.subLayerKey = SUBLAYER_KEY;
        filter.weight.type = FWP_EMPTY;

        conds[0].fieldKey = FWPM_CONDITION_IP_REMOTE_PORT;
        conds[0].matchType = FWP_MATCH_EQUAL;
        conds[0].conditionValue.type = FWP_UINT16;
        conds[0].conditionValue.uint16 = 53;

        conds[1].fieldKey = FWPM_CONDITION_ALE_APP_ID;
        conds[1].matchType = FWP_MATCH_NOT_EQUAL;
        conds[1].conditionValue.type = FWP_BYTE_BLOB_TYPE;
        conds[1].conditionValue.byteBlob = appBlob;

        conds[2].fieldKey = FWPM_CONDITION_INTERFACE_INDEX;
        conds[2].matchType = FWP_MATCH_NOT_EQUAL;
        conds[2].conditionValue.type = FWP_UINT32;
        conds[2].conditionValue.uint32 = (UINT32)index;
        filter.numFilterConditions = 3;
        filter.filterCondition = conds;
        filter.layerKey = FWPM_LAYER_ALE_AUTH_CONNECT_V4;
        result = FwpmFilterAdd0(_engine, &filter, NULL, NULL);
        EXIT_ON_ERROR(FwpmFilterAdd0)
        filter.layerKey = FWPM_LAYER_ALE_AUTH_CONNECT_V6;
        result = FwpmFilterAdd0(_engine, &filter, NULL, NULL);
        EXIT_ON_ERROR(FwpmFilterAdd0)
    CLEANUP:
        if (appBlob != NULL)
        {
            FwpmFreeMemory0((void **)&appBlob);
        }
        if (error.length() > 0)
        {
            FwpmEngineClose0(_engine);
            throw std::runtime_error(error);
        }
        return;
    }

    void DisableDefaultDns::Undo()
    {
        if (_engine != NULL)
        {
            FwpmEngineClose0(_engine);
            _engine = NULL;
        }
    }

}