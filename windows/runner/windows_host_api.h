#ifndef WINDOWS_HOST_API_H
#define WINDOWS_HOST_API_H

#include "messages.g.h"
#include <windows.h>
#include <fwpmu.h>

namespace x
{
    extern MessageFlutterApi* message_api;

    HANDLE _addSession(
         wchar_t *sessionName,
         wchar_t *providerName,
         wchar_t *sublayerName,
        const GUID *providerKey,
        const GUID *sublayerKey);

    class DisableDefaultDns
    {
    public:
        DisableDefaultDns();
        ~DisableDefaultDns();
        void Do(int64_t index);
        void Undo();

    private:
        HANDLE _engine{NULL};
    };

	class WindowsHostApiImpl : public WindowsHostApi
    {
    public:
        WindowsHostApiImpl();
        virtual ~WindowsHostApiImpl();

        std::optional<FlutterError> DisableDNS(int64_t index) override;
        std::optional<FlutterError> UndoDisableDNS() override;
        ErrorOr<bool> IsRunningAsAdmin() override;

    private:
        HANDLE _engine{NULL};
        std::unique_ptr<DisableDefaultDns> _disableDefaultDns;
        void _uninstallProvider();
    };

};
#endif
