/***

Compile with

cl /O2 /Ot /Ox /Oy /EHsc /GA /permissive- /utf-8 /validate-charset /MD /W4 launchpdf.cc

***/

/* Suppress unused parameter warning. */
#pragma warning(disable: 4100)
#pragma comment(lib, "user32")
#pragma comment(lib, "ole32")
#pragma comment(lib, "shlwapi")
#pragma comment(lib, "shell32")
#define UNICODE
#define _UNICODE
#define WIN32_LEAD_AND_MEAN
#include<windows.h>
#include<objbase.h>
#include<shlwapi.h>
#include<shellapi.h>
#include<shlobj.h>
#include<cstdlib>
#include<new>

struct CallCoUninitialize { ~CallCoUninitialize(); };
HRESULT SetGlobalOptions();

bool IsCOMServer(LPCWSTR cmdline);
HRESULT OpenFilesFromCmdLine(PWSTR cmdline);

HRESULT LaunchCOMServer();

int WINAPI wWinMain(HINSTANCE hinst, HINSTANCE hinstPrev,
  PWSTR lpCmdLine, int nShowCmd)
{
  HRESULT hr;
  if (!SUCCEEDED(hr = CoInitialize(NULL)))
  {
    return hr;
  }
  CallCoUninitialize xCoUninitialize;
  if (!SUCCEEDED(hr = SetGlobalOptions()))
  {
    return hr;
  }
  if (!IsCOMServer(lpCmdLine))
  {
    return OpenFilesFromCmdLine(lpCmdLine);
  }
  if (!SUCCEEDED(hr = LaunchCOMServer()))
  {
    return hr;
  }
  MSG msg;
  while (GetMessage(&msg, NULL, 0, 0))
  {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }
  return 0;
}

LPCWSTR const PROGRAM_NAME = L"PDF Launcher"; 

/*** Open files. ***/
void ChooseAssocClass(LPCWSTR file, SHELLEXECUTEINFOW *sei)
{
  sei->lpVerb = L"Open";
  sei->lpClass = L"Acrobat.Document.DC";
  /* Get the "real" (long) file name. */
  WCHAR file2[300] = {};
  DWORD ret = GetLongPathNameW(file, file2, 295);
  if (ret <= 0 || ret > 290)
  {
    return;
  }
  LPWSTR ext = (LPWSTR)PathFindExtensionW(file2);
  /* Safe to read ext[4] because ret < 290. */
  if (*ext != '.' || ext[4] != 0
    || (ext[1] != 'P' && ext[1] != 'p')
    || (ext[2] != 'D' && ext[2] != 'd')
    || (ext[3] != 'F' && ext[3] != 'f'))
  {
    return;
  }
  ext[1] = 't';
  ext[2] = 'e';
  ext[3] = 'x';
  if (PathFileExistsW(file2))
  {
    sei->lpVerb = L"open";
    sei->lpClass = L"MiKTeX.pdf.2.9";
  }
}
HRESULT OpenFile(LPCWSTR file, bool ddewait)
{
  SHELLEXECUTEINFOW sei = { sizeof(sei) };
  sei.fMask = SEE_MASK_CLASSNAME | SEE_MASK_UNICODE
    | (ddewait ? SEE_MASK_NOASYNC : SEE_MASK_ASYNCOK);
  sei.lpFile = file;
  sei.nShow = SW_SHOWNORMAL;
  ChooseAssocClass(file, &sei);
  return ShellExecuteExW(&sei) ? S_OK : HRESULT_FROM_WIN32(GetLastError());
}
struct CallReleaseStgMedium
{
  CallReleaseStgMedium(STGMEDIUM *target) : myMedium(target) { }
  ~CallReleaseStgMedium() { ReleaseStgMedium(myMedium); }
private:
  STGMEDIUM *myMedium;
};
HRESULT OpenFilesFromDataObject(IDataObject *pdto)
{
  HRESULT hr;
  FORMATETC format = { CF_HDROP, NULL, DVASPECT_CONTENT, -1, TYMED_HGLOBAL };
  STGMEDIUM medium;
  if (!SUCCEEDED(hr = pdto->GetData(&format, &medium)))
  {
    return hr;
  }
  CallReleaseStgMedium xReleaseStgMedium(&medium);
  HDROP files = reinterpret_cast<HDROP>(medium.hGlobal);
  UINT count = DragQueryFileW(files, 0xFFFFFFFF, NULL, 0);
  WCHAR path[300];
  for (UINT i = 0; i != count; ++i)
  {
    UINT length = DragQueryFileW(files, i, NULL, 0);
    if (length == 0)
    {
      return HRESULT_FROM_WIN32(GetLastError());
    }
    if (length > 290)
    {
      return HRESULT_FROM_WIN32(ERROR_BUFFER_OVERFLOW);
    }
    path[length++] = 0;
    path[length] = 0;
    if (!DragQueryFileW(files, i, path, length))
    {
      return HRESULT_FROM_WIN32(GetLastError());
    }
    /* Since the COM server is long-lived, we use asynchronous call. */
    if (!SUCCEEDED(hr = OpenFile(path, false)))
    {
      return hr;
    }
  }
  return S_OK;
}

/*** IDropTarget ***/
struct PdfOpenTarget : public IDropTarget
{
  /** IUnknown **/
  STDMETHODIMP QueryInterface(REFIID riid, void **ppv)
  {
    if (riid == IID_IDropTarget)
    {
      *ppv = static_cast<IDropTarget *>(this);
      AddRef();
      return S_OK;
    }
    if (riid == IID_IUnknown)
    {
      *ppv = static_cast<IUnknown *>(this);
      AddRef();
      return S_OK;
    }
    *ppv = NULL;
    return E_NOINTERFACE;
  }
  STDMETHODIMP_(ULONG) AddRef()
  {
    ++myRefCount;
    return 2;
  }
  STDMETHODIMP_(ULONG) Release()
  {
    if (--myRefCount != 0)
    {
      return 1;
    }
    this->~PdfOpenTarget();
    std::free(this);
    return 0;
  }
  /** IDropTarget **/
  STDMETHODIMP DragEnter(IDataObject *pdto,
    DWORD grfKeyState, POINTL ptl, DWORD *pdwEffect)
  {
    *pdwEffect &= DROPEFFECT_COPY;
    return S_OK;
  }
  STDMETHODIMP DragOver(DWORD grfKeyState, POINTL ptl, DWORD *pdwEffect)
  {
    *pdwEffect &= DROPEFFECT_COPY;
    return S_OK;
  }
  STDMETHODIMP DragLeave()
  {
    return S_OK;
  }
  STDMETHODIMP Drop(IDataObject *pdto,
    DWORD grfKeyState, POINTL ptl, DWORD *pdwEffect)
  {
    *pdwEffect &= DROPEFFECT_COPY;
    return OpenFilesFromDataObject(pdto);
  }
  /** C++ **/
  PdfOpenTarget() : myRefCount(1) { }
  ~PdfOpenTarget() { }
private:
  ULONG myRefCount;
};

CLSID const CLSID_PdfOpenTarget =
/* 82ede266-3bf0-435d-9f9a-21ae88aaef6c */
{0x82ede266,0x3bf0,0x435d,{0x9f,0x9a,0x21,0xae,0x88,0xaa,0xef,0x6c}};

struct ClassFactory : public IClassFactory
{
  /** IUnknown **/
  STDMETHODIMP QueryInterface(REFIID riid, void **ppv)
  {
    if (riid == IID_IClassFactory)
    {
      *ppv = static_cast<IClassFactory *>(this);
      return S_OK;
    }
    if (riid == IID_IUnknown)
    {
      *ppv = static_cast<IUnknown *>(this);
      return S_OK;
    }
    *ppv = NULL;
    return E_NOINTERFACE;
  }
  STDMETHODIMP_(ULONG) AddRef()
  {
    return 2;
  }
  STDMETHODIMP_(ULONG) Release()
  {
    return 1;
  }
  /** IClassFactory **/
  STDMETHODIMP CreateInstance(IUnknown *punkOuter, REFIID riid, void **ppv)
  {
    *ppv = NULL;
    if (punkOuter != NULL)
    {
      return CLASS_E_NOAGGREGATION;
    }
    void *storage = std::malloc(sizeof(PdfOpenTarget));
    if (!storage)
    {
      return E_OUTOFMEMORY;
    }
    PdfOpenTarget *target = new (storage) PdfOpenTarget();
    HRESULT hr = target->QueryInterface(riid, ppv);
    target->Release();
    return hr;
  }
  STDMETHODIMP LockServer(BOOL fLock)
  {
    return S_OK;
  }
} theClassFactory;

/*** RAII for CoUninitialize. ***/
CallCoUninitialize::~CallCoUninitialize() { CoUninitialize(); }

/*** Disable exception swallowing. ***/
HRESULT SetGlobalOptions()
{
  IGlobalOptions *globalOptions;
  HRESULT hr;
  if (!SUCCEEDED(hr = CoCreateInstance(CLSID_GlobalOptions, NULL,
    CLSCTX_INPROC_SERVER, IID_IGlobalOptions, (void **)&globalOptions)))
  {
    return hr;
  }
  hr = globalOptions->Set(COMGLB_EXCEPTION_HANDLING,
    COMGLB_EXCEPTION_DONOT_HANDLE_ANY);
  globalOptions->Release();
  return hr;
}

/*** COM server. ***/
HRESULT LaunchCOMServer()
{
  DWORD dwCookie;
  return CoRegisterClassObject(CLSID_PdfOpenTarget,
    static_cast<IUnknown *>(&theClassFactory),
    CLSCTX_LOCAL_SERVER, REGCLS_MULTIPLEUSE, &dwCookie);
}

bool IsCOMServer(LPCWSTR cmdline)
{
  /* Skip leading whitespace. */
  while (*cmdline == L' ')
  {
    ++cmdline;
  }
  /* No argument. */
  if (!*cmdline)
  {
    return false;
  }
  /* Check first argument. */
  bool quoting = false;
  LPCWSTR lower = L"-embedding";
  LPCWSTR upper = L"/EMBEDDING";
  for (int i = 0; lower[i]; ++i, ++cmdline)
  {
    /* -Embedding and /Embedding are not affected by quotation marks. */
    while (*cmdline == L'"')
    {
      quoting = !quoting;
      ++cmdline;
    }
    if (*cmdline != lower[i] && *cmdline != upper[i])
    {
      return false;
    }
  }
  /* There can be quotation marks after the textual content. */
  while (*cmdline == L'"')
  {
    quoting = !quoting;
    ++cmdline;
  }
  /* The command line ends. */
  if (!*cmdline)
  {
    return true;
  }
  /* This cannot be part of trailing whitespace. */
  if (quoting)
  {
    return false;
  }
  /* Skip whitespace. */
  while (*cmdline == L' ')
  {
    ++cmdline;
  }
  /* Check if we have reached the end. */
  return !*cmdline;
}

/*** Fallback to command line. ***/
HRESULT OpenFilesFromCmdLine(PWSTR cmdline)
{
  HRESULT hrReturn = S_OK, hr;
  while (true)
  {
    /* Skip whitespace. */
    while (*cmdline == ' ')
    {
      ++cmdline;
    }
    /* Command line ends. */
    if (!*cmdline)
    {
      return hrReturn;
    }
    LPCWSTR path = cmdline;
    PWSTR it = cmdline;
    bool quoting = false;
    int backslash = 0;
    for (WCHAR ch = *cmdline; true; ch = *(++cmdline))
    {
      if (ch == L'\\')
      {
        ++backslash;
        continue;
      }
      /* Write pending backslashes. */
      if (ch == L'"') /* Backslashes are paired. */
      {
        for (int i = (backslash >> 1); i != 0; --i)
        {
          *(it++) = L'\\';
        }
        backslash &= 1;
      }
      else /* Backslashes are literal. */
      {
        for (int i = backslash; i != 0; --i)
        {
          *(it++) = L'\\';
        }
        backslash = 0;
      }
      /* The current argument ends. */
      if (ch == 0 || (!quoting && ch == L' '))
      {
        *(it++) = 0;
        /* Use synchronous call to avoid using ProcessReference. */
        if (!SUCCEEDED(hr = OpenFile(path, true)) && hrReturn != S_OK)
        {
          hrReturn = hr;
        }
        if (ch == 0)
        {
          return hrReturn;
        }
        ++cmdline;
        break;
      }
      /* The current argument continues. */
      if (backslash == 0 && ch == L'"') /* This is a delimiter. */
      {
        quoting = !quoting;
      }
      else /* This is a literal character. */
      {
        *(it++) = ch;
        backslash = 0;
      }
    }
  }
}
