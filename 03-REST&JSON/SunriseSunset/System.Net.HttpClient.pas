{*******************************************************}
{                                                       }
{           CodeGear Delphi Runtime Library             }
{ Copyright(c) 2016 Embarcadero Technologies, Inc.      }
{              All rights reserved                      }
{                                                       }
{*******************************************************}

/// <summary>Unit that holds functionality relative to an HTTP Client</summary>
unit System.Net.HttpClient;

interface

{$IFDEF MSWINDOWS}
{$HPPEMIT '#pragma comment(lib, "winhttp")'}
{$HPPEMIT '#pragma comment(lib, "crypt32")'}
{$ENDIF}

{$SCOPEDENUMS ON}

uses
  System.Classes, System.Generics.Collections, System.Net.URLClient, System.Net.Mime, System.Sysutils, System.Types;

type
  /// <summary>Exceptions related to HTTP</summary>
  ENetHTTPException = class(ENetURIException);
  /// <summary>Exceptions related to HTTPClient</summary>
  ENetHTTPClientException = class(ENetURIClientException);
  /// <summary>Exceptions related to HTTPRequest</summary>
  ENetHTTPRequestException = class(ENetURIRequestException);
  /// <summary>Exceptions related to HTTPResponse</summary>
  ENetHTTPResponseException = class(ENetURIResponseException);

  /// <summary>Exceptions related to Certificates</summary>
  ENetHTTPCertificateException = class(ENetURIException);

  /// <summary>HTTP Protocol version</summary>
  THTTPProtocolVersion = (UNKNOWN_HTTP, HTTP_1_0, HTTP_1_1, HTTP_2_0);


const
  sHTTPMethodConnect = 'CONNECT'; // do not localize
  sHTTPMethodDelete = 'DELETE'; // do not localize
  sHTTPMethodGet = 'GET'; // do not localize
  sHTTPMethodHead = 'HEAD'; // do not localize
  sHTTPMethodOptions = 'OPTIONS'; // do not localize
  sHTTPMethodPost = 'POST'; // do not localize
  sHTTPMethodPut = 'PUT'; // do not localize
  sHTTPMethodTrace = 'TRACE'; // do not localize
  sHTTPMethodMerge = 'MERGE'; // do not localize
  sHTTPMethodPatch = 'PATCH'; // do not localize

// -------------------------------------------------------------------------------- //
// -------------------------------------------------------------------------------- //

type
  /// <summary>Signature of ReceiveData Callback</summary>
  TReceiveDataCallback = procedure(const Sender: TObject; AContentLength: Int64; AReadCount: Int64; var Abort: Boolean);

  /// <summary>Signature of ReceiveData Event</summary>
  TReceiveDataEvent = procedure(const Sender: TObject; AContentLength: Int64; AReadCount: Int64; var Abort: Boolean) of object;

// -------------------------------------------------------------------------------- //
// -------------------------------------------------------------------------------- //
  /// <summary>Cookie record.</summary>
  TCookie = record
  private
    class function StrExpiresToDateTime(const AStrDate: string): TDateTime; static;
  public
    /// <summary>Cookie Name</summary>
    Name: string;
    /// <summary>Cookie Value</summary>
    Value: string;
    /// <summary>Cookie Expires. It's the date when the cookie will expire</summary>
    /// <remarks>When Expires is 0 means a session cookie.</remarks>
    Expires: TDateTime;
    /// <summary>Cookie Domain</summary>
    Domain: string;
    /// <summary>Cookie Path</summary>
    Path: string;
    /// <summary>Cookie Secure</summary>
    /// <remarks>If True then the cookie will be sent if https scheme is used</remarks>
    Secure: Boolean;
    /// <summary>Cookie HttpOnly</summary>
    /// <remarks>If True then the cookie will not be used in javascript, it's browser dependant.</remarks>
    HttpOnly: Boolean;

    /// <summary>Return the cookie as string to be send to the server</summary>
    function ToString: string;
    /// <summary>Return a TCookie parsing ACookieData based on the URI param</summary>
    class function Create(const ACookieData: string; const AURI: TURI): TCookie; static;
  end;

  /// <summary>Container for cookies</summary>
  TCookies = class(TList<TCookie>);
  TCookiesArray = TArray<TCookie>;

  /// <summary> Class to manage Cookies</summary>
  TCookieManager = class
  private
    FCookies: TCookies;
    procedure UpdateCookie(const ACookie: TCookie; const AURL: TURI);
    function ValidCookie(const ACookie: TCookie; const AURL: TURI): Boolean; inline;
    function GetCookies: TCookiesArray;
    procedure DeleteExpiredCookies;
  public
    /// <summary> Adds a Server cookie to the cookie storage </summary>
    procedure AddServerCookie(const ACookieData, ACookieURL: string); overload; inline;
    procedure AddServerCookie(const ACookie: TCookie; const AURL: TURI); overload;
    /// <summary>Generate the client cookie headers based on the URI param</summary>
    function CookieHeaders(const AURI: TURI): string;
    constructor Create;
    destructor Destroy; override;

    /// <summary>Returns an array with the cookies</summary>
    property Cookies: TCookiesArray read GetCookies;
  end;

// -------------------------------------------------------------------------------- //
// -------------------------------------------------------------------------------- //

  /// <summary>Interface for HTTPRequest</summary>
  IHTTPRequest = interface(IURLRequest)
    /// <summary>Getter for the Property HeaderValue</summary>
    function GetHeaderValue(const AName: string): string;
    /// <summary>Setter for the Property HeaderValue</summary>
    procedure SetHeaderValue(const AName, AValue: string);
    /// <summary>Property to Get/Set Header values</summary>
    /// <param name="AName">Name of the Header</param>
    /// <returns>The string value associated to the given name.</returns>
    property HeaderValue[const AName: string]: string read GetHeaderValue write SetHeaderValue;

    /// <summary>Getter for the Headers Property from the Request</summary>
    function GetHeaders: TNetHeaders;
    /// <summary>Property to Get/Set all Headers from the Request</summary>
    /// <returns>A TStrings containing all Headers with theirs respective values.</returns>
    property Headers: TNetHeaders read GetHeaders;

    /// <summary>Add a Header to the current request.</summary>
    /// <param name="AName">Name of the Header.</param>
    /// <param name="AValue">Value associted.</param>
    procedure AddHeader(const AName, AValue: string);

    /// <summary>Removes a Header from the request</summary>
    /// <param name="AName">Header to be removed.</param>
    function RemoveHeader(const AName: string): Boolean;

    // Helper functions to get/set common Header values
    /// <summary>Getter for the Accept Property</summary>
    function GetAccept: string;
    /// <summary>Getter for the AcceptCharSet Property</summary>
    function GetAcceptCharSet: string;
    /// <summary>Getter for the AcceptEncoding Property</summary>
    function GetAcceptEncoding: string;
    /// <summary>Getter for the AcceptLanguage Property</summary>
    function GetAcceptLanguage: string;
    /// <summary>Getter for the UserAgent Property</summary>
    function GetUserAgent: string;
    /// <summary>Setter for the Accept Property</summary>
    procedure SetAccept(const Value: string);
    /// <summary>Setter for the AcceptCharSet Property</summary>
    procedure SetAcceptCharSet(const Value: string);
    /// <summary>Setter for the AcceptEncoding Property</summary>
    procedure SetAcceptEncoding(const Value: string);
    /// <summary>Setter for the AcceptLanguage Property</summary>
    procedure SetAcceptLanguage(const Value: string);
    /// <summary>Setter for the UserAgent Property</summary>
    procedure SetUserAgent(const Value: string);
    /// <summary>Get the client certificate assigned to the request</summary>
    function GetClientCertificate: TStream;
    /// <summary>iOS only: we can set a client certificate to use with the request</summary>
    procedure SetClientCertificate(const Value: TStream; const Password: string);
    /// <summary>UserAgent Property</summary>
    property UserAgent: string read GetUserAgent write SetUserAgent;
    /// <summary>Accept Property</summary>
    property Accept: string read GetAccept write SetAccept;
    /// <summary>AcceptCharSet Property</summary>
    property AcceptCharSet: string read GetAcceptCharSet write SetAcceptCharSet;
    /// <summary>AcceptEncoding Property</summary>
    property AcceptEncoding: string read GetAcceptEncoding write SetAcceptEncoding;
    /// <summary>AcceptLanguage Property</summary>
    property AcceptLanguage: string read GetAcceptLanguage write SetAcceptLanguage;

    /// <summary> Getter for the ReceiveData Callback Property</summary>
    function GetReceiveDataCallback: TReceiveDataCallback;
    /// <summary> Setter for the ReceiveData Callback Property</summary>
    procedure SetReceiveDataCallback(const Value: TReceiveDataCallback);
    /// <summary> Getter for the ReceiveData Callback Event</summary>
    function GetReceiveDataEvent: TReceiveDataEvent;
    /// <summary> Setter for the ReceiveData Callback Event</summary>
    procedure SetReceiveDataEvent(const Value: TReceiveDataEvent);
    /// <summary>Property to manage the ReceiveData Callback</summary>
    property ReceiveDataCallback: TReceiveDataCallback read GetReceiveDataCallback write SetReceiveDataCallback;
    /// <summary>Property to manage the ReceiveData Event</summary>
    property OnReceiveData: TReceiveDataEvent read GetReceiveDataEvent write SetReceiveDataEvent;
  end;

// -------------------------------------------------------------------------------- //
// -------------------------------------------------------------------------------- //

  // Forwarded class.
  THTTPClient = class;

  /// <summary>Specific Class to handle HTTP Requests</summary>
  /// <remarks></remarks>
  THTTPRequest = class(TURLRequest, IHTTPRequest)
  private
    FReceiveDataCallback: TReceiveDataCallback;
    FOnReceiveData: TReceiveDataEvent;
    FOwnedStream: TStream;
    {IHTTPRequest}
    // Helper functions to get/set common Header values
    function GetAccept: string;
    function GetAcceptCharSet: string;
    function GetAcceptEncoding: string;
    function GetAcceptLanguage: string;
    function GetUserAgent: string;
    procedure SetAccept(const Value: string);
    procedure SetAcceptCharSet(const Value: string);
    procedure SetAcceptEncoding(const Value: string);
    procedure SetAcceptLanguage(const Value: string);
    procedure SetUserAgent(const Value: string);
    function GetReceiveDataCallback: TReceiveDataCallback;
    procedure SetReceiveDataCallback(const Value: TReceiveDataCallback);
    function GetReceiveDataEvent: TReceiveDataEvent;
    procedure SetReceiveDataEvent(const Value: TReceiveDataEvent);
    function GetClientCertificate: TStream;

  protected
    /// <summary>Contains the client certificate (raw data) to use with the request (iOS only)</summary>
    [Weak] FClientCertificate: TStream;
    /// <summary>To store the client certificate password (iOS only)</summary>
    FClientCertPassword: string;
    /// <summary>Checks and invokes ReceiveData Callback or OnReceiveData event</summary>
    procedure DoReceiveDataProgress(AStatusCode: Integer; AContentLength: Int64; AReadCount: Int64; var Abort: Boolean);
    /// <summary>Prepare Request to be executed</summary>
    procedure DoPrepare; virtual; abstract;
    /// <summary>Set the client certificate for the request</summary>
    procedure SetClientCertificate(const Value: TStream; const Password: string);

    constructor Create(const AClient: THTTPClient; const ARequestMethod: string; const AURI: TURI);
  public
    {IHTTPRequest}
    /// <summary>Getter for the Headers Property from the Request</summary>
    function GetHeaders: TNetHeaders; virtual; abstract;
    /// <summary>Getter for the Property HeaderValue</summary>
    function GetHeaderValue(const AName: string): string; virtual; abstract;
    /// <summary>Setter for the Property HeaderValue</summary>
    procedure SetHeaderValue(const AName, AValue: string); virtual; abstract;

    /// <summary>Add a Header to the current request.</summary>
    /// <param name="AName">Name of the Header.</param>
    /// <param name="AValue">Value associted.</param>
    procedure AddHeader(const AName, AValue: string); virtual; abstract;

    /// <summary>Removes a Header from the request</summary>
    /// <param name="AName">Header to be removed.</param>
    function RemoveHeader(const AName: string): Boolean; virtual; abstract;

    /// <summary>Property to manage the ReceiveData Callback</summary>
    property ReceiveDataCallback: TReceiveDataCallback read GetReceiveDataCallback write SetReceiveDataCallback;

    /// <summary>Property to manage the ReceiveData Event</summary>
    property OnReceiveData: TReceiveDataEvent read GetReceiveDataEvent write SetReceiveDataEvent;
  public
    destructor Destroy; override;
  end;

// -------------------------------------------------------------------------------- //
// -------------------------------------------------------------------------------- //

  /// <summary>Interface for HTTPResponse</summary>
  IHTTPResponse = interface(IURLResponse)
    ['{ED07313B-324B-448F-84AD-F199D38981DA}']

    /// <summary>Getter for the HeaderValue Property</summary>
    function GetHeaderValue(const AName: string): string;
    /// <summary>Getter for the ContentCharSet Standard Header Property</summary>
    function GetContentCharSet: string;
    /// <summary>Getter for the ContentEncoding Standard Header Property</summary>
    function GetContentEncoding: string;
    /// <summary>Getter for the ContentLanguage Standard Header Property</summary>
    function GetContentLanguage: string;
    /// <summary>Getter for the ContentLength Standard Header Property</summary>
    function GetContentLength: Int64;
    /// <summary>Getter for the Date Standard Header Property</summary>
    function GetDate: string;
    /// <summary>Getter for the LastModified Standard Header Property</summary>
    function GetLastModified: string;
    /// <summary>Getter for the StatusCode Property</summary>
    function GetStatusCode: Integer;
    /// <summary>Getter for the StatusText Property</summary>
    function GetStatusText: string;
    /// <summary>Getter for the Version Property</summary>
    function GetVersion: THTTPProtocolVersion;

    /// <summary>Function to know if a given header is present</summary>
    /// <param name="AName">Name of the Header</param>
    /// <returns>True if the Header is present.</returns>
    function ContainsHeader(const AName: string): Boolean;

    /// <summary>Getter for the Cookies Property</summary>
    function GetCookies: TCookies;

    /// <summary>Property to Get Header values</summary>
    /// <param name="AName">Name of the Header</param>
    /// <returns>The string value associated to the given name.</returns>
    property HeaderValue[const AName: string]: string read GetHeaderValue;

    /// <summary>Get ContentCharSet from server response</summary>
    property ContentCharSet: string read GetContentCharSet;
    /// <summary>Get ContentEncoding from server response</summary>
    property ContentEncoding: string read GetContentEncoding;
    /// <summary>Get ContentLanguage from server response</summary>
    property ContentLanguage: string read GetContentLanguage;
    /// <summary>Get ContentLength from server response</summary>
    property ContentLength: Int64 read GetContentLength;

    /// <summary>Get Date from server response</summary>
    property Date: string read GetDate;
    /// <summary>Get LastModified from server response</summary>
    property LastModified: string read GetLastModified;

    /// <summary>Get StatusText from server response</summary>
    property StatusText: string read GetStatusText;
    /// <summary>Get StatusCode from server response</summary>
    property StatusCode: Integer read GetStatusCode;
    /// <summary>Get Version from server response</summary>
    property Version: THTTPProtocolVersion read GetVersion;
    /// <summary>Get Cookies from server response</summary>
    property Cookies: TCookies read GetCookies;
  end;

  /// <summary>Class that implements a HTTP response.</summary>
  THTTPResponse = class(TURLResponse, IHTTPResponse)
  protected
    /// <summary>Headers obtained from the response</summary>
    FHeaders: TNetHeaders;

    /// <summary>Request that originate the response</summary>
    FRequest: IHTTPRequest;

    /// <summary>Cookies received from server</summary>
    FCookies: TCookies;

    /// <summary>Platform dependant Implementation for reading the data from the response into a stream</summary>
    procedure DoReadData(const AStream: TStream); virtual; abstract;

  public
    {IURLResponse}
    /// <summary>Implementation of IURLResponse Getter for the ContentStream property</summary>
    function GetContentStream: TStream;

    /// <summary>Implementation of IURLResponse Getter for the MimeType property</summary>
    function GetMimeType: string; override;
    /// <summary>Implementation of IURLResponse ContentAsString</summary>
    /// <remarks>If you do not provide AEncoding then the system will try to get it from the response</remarks>
    function ContentAsString(const AnEncoding: TEncoding = nil): string; override;

    {IHTTPResponse}
    /// <summary>Implementation of IHTTPResponse for ContainsHeader</summary>
    function ContainsHeader(const AName: string): Boolean; virtual;
    /// <summary>Implementation of IHTTPResponse Getter for the HeaderValue property</summary>
    function GetHeaderValue(const AName: string): string; virtual;
    /// <summary>Implementation of IHTTPResponse Getter for the ContentCharSet property</summary>
    function GetContentCharSet: string; virtual;
    /// <summary>Implementation of IHTTPResponse Getter for the ContentEncoding property</summary>
    function GetContentEncoding: string; virtual;
    /// <summary>Implementation of IHTTPResponse Getter for the ContentLanguage property</summary>
    function GetContentLanguage: string; virtual;
    /// <summary>Implementation of IHTTPResponse Getter for the ContentLength property</summary>
    function GetContentLength: Int64; virtual;
    /// <summary>Implementation of IHTTPResponse Getter for the Date property</summary>
    function GetDate: string; virtual;
    /// <summary>Implementation of IHTTPResponse Getter for the LastModified property</summary>
    function GetLastModified: string; virtual;
    /// <summary>Implementation of IHTTPResponse Getter for the StatusCode property</summary>
    /// <remarks>Must be overriden in platform Implementation.</remarks>
    function GetStatusCode: Integer; virtual; abstract;
    /// <summary>Implementation of IHTTPResponse Getter for the StatusText property</summary>
    /// <remarks>Must be overriden in platform Implementation.</remarks>
    function GetStatusText: string; virtual; abstract;
    /// <summary>Implementation of IHTTPResponse Getter for the Version property</summary>
    /// <remarks>Must be overriden in platform Implementation.</remarks>
    function GetVersion: THTTPProtocolVersion; virtual; abstract;


    /// <summary>Implementation of IHTTPResponse Getter for the Cookies property</summary>
    function GetCookies: TCookies; virtual;

  protected
    /// <summary>Add cookie to response cookies</summary>
    /// <remarks>Internal use only, used in platform specific code</remarks>
    procedure InternalAddCookie(const ACookieData: string);
    /// <summary>Returns realm attribute from Server/Proxy Authentication response</summary>
    /// <remarks>Internal use only</remarks>
    function InternalGetAuthRealm: string;

    constructor Create(const AContext: TObject; const AProc: TProc;
      const AAsyncCallback: TAsyncCallback; const AAsyncCallbackEvent: TAsyncCallbackEvent;
      const ARequest: IHTTPRequest; const AContentStream: TStream); overload;
  public
    destructor Destroy; override;
  end;

// -------------------------------------------------------------------------------- //
// -------------------------------------------------------------------------------- //

  /// <summary> Class that implements a HTTP Client.</summary>
  THTTPClient = class(TURLClient)
  protected type
    TExecutionResult = (Success, UnknownError, ServerCertificateInvalid, ClientCertificateNeeded);
    InternalState = (Other, ProxyAuthRequired, ServerAuthRequired);
    THTTPState = record
      NeedProxyCredential: Boolean;
      ProxyCredential: TCredentialsStorage.TCredential;
      ProxyCredentials: TCredentialsStorage.TCredentialArray;
      ProxyIterator: Integer;
      NeedServerCredential: Boolean;
      ServerCredential: TCredentialsStorage.TCredential;
      ServerCredentials: TCredentialsStorage.TCredentialArray;
      ServerIterator: Integer;
      Status: InternalState;
      Redirections: Integer;
    end;
  private
    const DefaultMaxRedirects = 5; // As defined by "rfc2616.txt"
    procedure DoNeedClientCertificate(const LRequest: THTTPRequest; const LClientCertificateList: TCertificateList);
    procedure DoValidateServerCertificate(LRequest: THTTPRequest);
    procedure ExecuteHTTPInternal(const ARequest: IHTTPRequest; const AContentStream: TStream; const AResponse: IHTTPResponse);
    procedure ExecuteHTTP(const ARequest: IHTTPRequest; const AContentStream: TStream; const AResponse: IHTTPResponse); {$IFNDEF ANDROID} inline; {$ENDIF}
    function SetProxyCredential(const ARequest: THTTPRequest; const AResponse: THTTPResponse;
      var State: THTTPClient.THTTPState): Boolean;
    function SetServerCredential(const ARequest: THTTPRequest; const AResponse: THTTPResponse;
      var State: THTTPClient.THTTPState): Boolean;
  private
    FAllowCookies: Boolean;
    FHandleRedirects: Boolean;
    FReceiveDataCallback: TReceiveDataCallback;
    FOnReceiveData: TReceiveDataEvent;
    [Weak] FCookieManager: TCookieManager;
    FInternalCookieManager: TCookieManager;
    function GetAccept: string; inline;
    function GetAcceptCharSet: string; inline;
    function GetAcceptEncoding: string; inline;
    function GetAcceptLanguage: string; inline;
    procedure SetAccept(const Value: string); inline;
    procedure SetAcceptCharSet(const Value: string); inline;
    procedure SetAcceptEncoding(const Value: string); inline;
    procedure SetAcceptLanguage(const Value: string); inline;
    function GetContentType: string; inline;
    procedure SetContentType(const Value: string); inline;
    procedure SetCookieManager(const Value: TCookieManager);
    procedure UpdateCookiesFromResponse(const AResponse: THTTPResponse);
  protected
    /// <summary>Maximum number of redirects to be processed when executing a request.</summary>
    FMaxRedirects: Integer;
    /// <summary>User callback when a ClientCertificate is needed </summary>
    FNeedClientCertificateCallback: TNeedClientCertificateCallback;
    /// <summary>User event when a ClientCertificate is needed </summary>
    FNeedClientCertificateEvent: TNeedClientCertificateEvent;
    /// <summary>Callback called when is needed to Validate a Server certificate.</summary>
    FValidateServerCertificateCallback: TValidateCertificateCallback;
    /// <summary>Event called when is needed to Validate a Server certificate.</summary>
    FValidateServerCertificateEvent: TValidateCertificateEvent;

    /// <summary>Method to get the platform dependant Client Certificates.</summary>
    /// <remarks>Must be overriden in platform Implementation.</remarks>
    procedure DoGetClientCertificates(const ARequest: THTTPRequest; const ACertificateList: TList<TCertificate>); virtual; abstract;
    /// <summary>Method to be executed when the client certificate has been accepted.</summary>
    /// <remarks>Must be overriden in platform Implementation.</remarks>
    function DoClientCertificateAccepted(const ARequest: THTTPRequest; const AnIndex: Integer): Boolean; virtual; abstract;
    /// <summary>Method to get the platform dependant SSL Server Certificates.</summary>
    /// <remarks>Must be overriden in platform Implementation.</remarks>
    function DoGetSSLCertificateFromServer(const ARequest: THTTPRequest): TCertificate; virtual; abstract;
    /// <summary>Method to be executed when the client SSL server certificate has been accepted.</summary>
    /// <remarks>Must be overriden in platform Implementation.</remarks>
    procedure DoServerCertificateAccepted(const ARequest: THTTPRequest); virtual; abstract;
    /// <summary>Method to execute the platform dependant HTTP request.</summary>
    /// <remarks>Must be overriden in platform Implementation.</remarks>
    function DoExecuteRequest(const ARequest: THTTPRequest; var AResponse: THTTPResponse;
      const AContentStream: TStream): TExecutionResult; virtual; abstract;
    /// <summary>Method set the server/proxy credentials for a request.</summary>
    /// <remarks>Must be overriden in platform Implementation.</remarks>
    function DoSetCredential(AnAuthTargetType: TAuthTargetType; const ARequest: THTTPRequest;
      const ACredential: TCredentialsStorage.TCredential): Boolean; virtual; abstract;
    /// <summary>Method to execute specific actions after the request has been executed.</summary>
    /// <remarks>Must be overriden in platform Implementation.</remarks>
    function DoProcessStatus(const ARequest: IHTTPRequest; const  AResponse: IHTTPResponse): Boolean; virtual; abstract;

    /// <summary>Returns a new response instance from the client.</summary>
    /// <remarks>This function must be overriden by specific clients (HTTP, FTP, ...)</remarks>
    function DoGetResponseInstance(const AContext: TObject; const AProc: TProc; const AsyncCallback: TAsyncCallback;
      const AsyncCallbackEvent: TAsyncCallbackEvent; const ARequest: IHTTPRequest; const AContentStream: TStream): IHTTPResponse; reintroduce; virtual; abstract;

    /// <summary>Returns a new request instance from the client.</summary>
    function DoGetRequestInstance: IURLRequest; override;
    /// <summary> Method to get the platform dependant Request instance from a client.</summary>
    /// <remarks> Must be overriden in platform Implementation.</remarks>
    function DoGetHTTPRequestInstance(const AClient: THTTPClient; const ARequestMethod: string;
      const AURI: TURI): IHTTPRequest; virtual; abstract;

    /// <summary>Returns the supported schemes from the client.</summary>
    function SupportedSchemes: TArray<string>; override;

    function DoExecute(const ARequestMethod: string; const AURI: TURI;
      const ASourceStream, AContentStream: TStream; const AHeaders: TNetHeaders): IURLResponse; override;

    /// <summary>Function that asynchronusly executes a Request and obtains a response</summary>
    /// <remarks> This function creates a request before calling InternalExecuteAsync</remarks>
    function DoExecuteAsync(const AsyncCallback: TAsyncCallback; const AsyncCallbackEvent: TAsyncCallbackEvent;
      const ARequestMethod: string; const AURI: TURI; const ASourceStream, AContentStream: TStream;
      const AHeaders: TNetHeaders; AOwnsSourceStream: Boolean): IHTTPResponse; reintroduce;

    /// <summary>Function that asynchronusly executes a given Request and obtains a response</summary>
    function InternalExecuteAsync(const AsyncCallback: TAsyncCallback; const AsyncCallbackEvent: TAsyncCallbackEvent;
      const ARequest: IHTTPRequest; const AContentStream: TStream;
      const AHeaders: TNetHeaders; AOwnsSourceStream: Boolean): IHTTPResponse;

    /// <summary>Getter for the property MaxRedirects</summary>
    /// <returns>Maximum number of redirections to be performed.</returns>
    function GetMaxRedirects: Integer;
    /// <summary>Setter for the property MaxRedirects</summary>
    /// <remarks>Should be overriden in platform if is needed some processing when changing.</remarks>
    /// <param name="Value">Max number of redirections to be processed by the execution of the request.</param>
    procedure SetMaxRedirects(const Value: Integer); virtual;

    /// <summary>This function is like the constructor Create, but is called Initializer to avoid collision with
    /// class function Create.</summary>
    procedure Initializer;
  public
    destructor Destroy; override;
    /// <summary>You have to use this function as a constructor Create.</summary>
    /// <remarks>The user is responsible of freeing the obtained object instance</remarks>
    /// <returns>The platform Implementation of an HTTPClient</returns>
    class function Create: THTTPClient;

    /// <summary>Function that translates Encoding Names to valid Http Charset Names.</summary>
    class function EncodingNameToHttpEncodingName(const AEncodingName: string): string; static;

    /// <summary>Get a Request instance associated with the client for the given Request Method and URI</summary>
    /// <param name="ARequestMethod">Request method to be performed</param>
    /// <param name="AURI">URI to use for the Request</param>
    /// <returns>An interface to the request platform object.</returns>
    /// <remarks>Under 'Windows' This function can raise an exception if the URL's host cannot be reached.
    /// This is tested before doing the connection to the host. Under other platforms this exception is raised upon connection.
    /// in the Execute method. </remarks>
    /// <exception cref="ENetHTTPRequestException"> This is raised if URL's Host cannot be reached.</exception>
    function GetRequest(const ARequestMethod: string; const AURI: TURI): IHTTPRequest; overload;

    /// <summary>Get a Request instance associated with the client for the given Request Method and URI</summary>
    /// <param name="ARequestMethod">Request method to be performed</param>
    /// <param name="AURL">URL to use for the Request</param>
    /// <returns>An interface to the request platform object.</returns>
    /// <remarks>Under 'Windows' This function can raise an exception if the URL's host cannot be reached.
    /// This is tested before doing the connection to the host. Under other platforms this exception is raised upon connection.
    /// in the Execute method. </remarks>
    /// <exception cref="ENetHTTPRequestException"> This is raised if URL's Host cannot be reached.</exception>
    function GetRequest(const ARequestMethod, AURL: string): IHTTPRequest; overload; //inline;

    // ------------------------------------------- //
    // Standard HTTP Methods
    // ------------------------------------------- //
    /// <summary>Send 'DELETE' command to url</summary>
    function Delete(const AURL: string; const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse;
    /// <summary>Send asynchronous 'DELETE' command to url</summary>
    function BeginDelete(const AURL: string; const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginDelete(const AsyncCallback: TAsyncCallback; const AURL: string; const AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginDelete(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string; const AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;

    /// <summary>Send 'OPTIONS' command to url</summary>
    function Options(const AURL: string; const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse;
    /// <summary>Send asynchronous 'OPTIONS' command to url</summary>
    function BeginOptions(const AURL: string; const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginOptions(const AsyncCallback: TAsyncCallback; const AURL: string; const AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginOptions(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string; const AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;

    /// <summary>Send 'GET' command to url</summary>
    function Get(const AURL: string; const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse;
    /// <summary>Send asynchronous 'GET' command to url</summary>
    function BeginGet(const AURL: string; const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginGet(const AsyncCallback: TAsyncCallback; const AURL: string; const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginGet(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string; const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;


    /// <summary>Check if the server has download resume feature</summary>
    function CheckDownloadResume(const AURL: string): Boolean;

    /// <summary>Send 'GET' command to url adding Range header</summary>
    /// <remarks>It's used for resume downloads</remarks>
    function GetRange(const AURL: string; AStart: Int64; AnEnd: Int64 = -1; const AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse;
    /// <summary>Send asynchronous 'GET' command to url adding Range header</summary>
    /// <remarks>It's used for resume downloads</remarks>
    function BeginGetRange(const AURL: string; AStart: Int64; AnEnd: Int64 = -1; const AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginGetRange(const AsyncCallback: TAsyncCallback; const AURL: string; AStart: Int64; AnEnd: Int64 = -1;
      const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginGetRange(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string; AStart: Int64; AnEnd: Int64 = -1;
      const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;

    /// <summary>Send 'TRACE' command to url</summary>
    function Trace(const AURL: string; const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse;
    /// <summary>Send asynchronous 'TRACE' command to url</summary>
    function BeginTrace(const AURL: string; const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginTrace(const AsyncCallback: TAsyncCallback; const AURL: string; const AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginTrace(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string;
      const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;

    /// <summary>Send 'HEAD' command to url</summary>
    function Head(const AURL: string; const AHeaders: TNetHeaders = nil): IHTTPResponse;
    /// <summary>Send asynchronous 'HEAD' command to url</summary>
    function BeginHead(const AURL: string; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginHead(const AsyncCallback: TAsyncCallback; const AURL: string; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginHead(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;

    /// <summary>Post a raw file without multipart info</summary>
    function Post(const AURL: string; const ASourceFile: string; const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    /// <summary>Asynchronously Post a raw file without multipart info</summary>
    function BeginPost(const AURL: string; const ASourceFile: string; const AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginPost(const AsyncCallback: TAsyncCallback; const AURL: string; const ASourceFile: string; const AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginPost(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string; const ASourceFile: string; const AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;

    /// <summary>Post TStrings values adding multipart info</summary>
    function Post(const AURL: string; const ASource: TStrings; const AResponseContent: TStream = nil;
      const AEncoding: TEncoding = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    /// <summary>Asynchronously Post TStrings values adding multipart info</summary>
    function BeginPost(const AURL: string; const ASource: TStrings; const AResponseContent: TStream = nil;
      const AEncoding: TEncoding = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginPost(const AsyncCallback: TAsyncCallback; const AURL: string; const ASource: TStrings;
      const AResponseContent: TStream = nil; const AEncoding: TEncoding = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginPost(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string; const ASource: TStrings;
      const AResponseContent: TStream = nil; const AEncoding: TEncoding = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    /// <summary>Post a stream without multipart info</summary>
    function Post(const AURL: string; const ASource: TStream; const AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    /// <summary>Asynchronously Post a stream without multipart info</summary>
    function BeginPost(const AURL: string; const ASource: TStream; const AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginPost(const AsyncCallback: TAsyncCallback; const AURL: string; const ASource: TStream;
      const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginPost(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string; const ASource: TStream;
      const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    /// <summary>Post a multipart form data object</summary>
    function Post(const AURL: string; const ASource: TMultipartFormData; const AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    /// <summary>Asynchronously Post a multipart form data object</summary>
    function BeginPost(const AURL: string; const ASource: TMultipartFormData; const AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginPost(const AsyncCallback: TAsyncCallback; const AURL: string; const ASource: TMultipartFormData;
      const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginPost(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string; const ASource: TMultipartFormData;
      const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;

    /// <summary>Send 'PUT' command to url</summary>
    function Put(const AURL: string; const ASource: TStream = nil; const AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse;
    /// <summary>Asynchronously Send 'PUT' command to url</summary>
    function BeginPut(const AURL: string; const ASource: TStream = nil; const AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginPut(const AsyncCallback: TAsyncCallback; const AURL: string; const ASource: TStream = nil;
      const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginPut(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string; const ASource: TStream = nil;
      const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;

    // Non standard command procedures ...
    /// <summary>Send 'MERGE' command to url</summary>
    function Merge(const AURL: string; const ASource: TStream; const AHeaders: TNetHeaders = nil): IHTTPResponse;
    /// <summary>Asynchronously Send 'MERGE' command to url</summary>
    function BeginMerge(const AURL: string; const ASource: TStream; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginMerge(const AsyncCallback: TAsyncCallback; const AURL: string; const ASource: TStream;
      const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginMerge(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string; const ASource: TStream;
      const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    /// <summary>Send a special 'MERGE' command to url. Command based on a 'PUT' + 'x-method-override' </summary>
    function MergeAlternative(const AURL: string; const ASource: TStream; const AHeaders: TNetHeaders = nil): IHTTPResponse;
    /// <summary>Asynchronously Send a special 'MERGE' command to url. Command based on a 'PUT' + 'x-method-override' </summary>
    function BeginMergeAlternative(const AURL: string; const ASource: TStream; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginMergeAlternative(const AsyncCallback: TAsyncCallback; const AURL: string; const ASource: TStream;
      const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginMergeAlternative(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string;
      const ASource: TStream; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    /// <summary>Send 'PATCH' command to url</summary>
    function Patch(const AURL: string; const ASource: TStream = nil; const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse;
    /// <summary>Asynchronously Send 'PATCH' command to url</summary>
    function BeginPatch(const AURL: string; const ASource: TStream = nil; const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginPatch(const AsyncCallback: TAsyncCallback; const AURL: string; const ASource: TStream = nil;
      const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginPatch(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string; const ASource: TStream = nil;
      const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    /// <summary>Send a special 'PATCH' command to url. Command based on a 'PUT' + 'x-method-override' </summary>
    function PatchAlternative(const AURL: string; const ASource: TStream = nil; const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse;
    /// <summary>Asynchronously Send a special 'PATCH' command to url. Command based on a 'PUT' + 'x-method-override' </summary>
    function BeginPatchAlternative(const AURL: string; const ASource: TStream = nil; const AResponseContent: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginPatchAlternative(const AsyncCallback: TAsyncCallback; const AURL: string; const ASource: TStream = nil;
      const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    function BeginPatchAlternative(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string;
      const ASource: TStream = nil; const AResponseContent: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;


    // Execute functions for performing requests ...
    /// <summary>You have to use this function to Execute a given Request</summary>
    /// <param name="ARequest">The request that is going to be Executed</param>
    /// <param name="AContentStream">The stream to store the response data. If provided the user is responsible
    /// of releasing it. If not provided will be created internally and released when not needed.</param>
    /// <param name="AHeaders">Additional Headers to pass to the request that is going to be Executed</param>
    /// <returns>The platform dependant response object associated to the given request. It's an Interfaced object and
    /// It's released automatically.</returns>
    function Execute(const ARequest: IHTTPRequest; const AContentStream: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;

    /// <summary>You have to use this function to Asynchronously Execute a given Request</summary>
    /// <param name="ARequest">The request that is going to be Executed</param>
    /// <param name="AContentStream">The stream to store the response data. If provided the user is responsible
    /// of releasing it. If not provided will be created internally and released when not needed.</param>
    /// <param name="AHeaders">Additional Headers to pass to the request that is going to be Executed</param>
    /// <returns>The Asynchronous Result object associated to the given request. It's an Interfaced object and
    /// It's released automatically.</returns>
    function BeginExecute(const ARequest: IHTTPRequest; const AContentStream: TStream = nil;
      const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    /// <summary>You have to use this function to Asynchronously Execute a given Request</summary>
    /// <param name="AsyncCallback">The Callback that is going to be Executed when the Request finishes.</param>
    /// <param name="ARequest">The request that is going to be Executed</param>
    /// <param name="AContentStream">The stream to store the response data. If provided the user is responsible
    /// of releasing it. If not provided will be created internally and released when not needed.</param>
    /// <param name="AHeaders">Additional Headers to pass to the request that is going to be Executed</param>
    /// <returns>The Asynchronous Result object associated to the given request. It's an Interfaced object and
    /// It's released automatically.</returns>
    function BeginExecute(const AsyncCallback: TAsyncCallback; const ARequest: IHTTPRequest;
      const AContentStream: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;
    /// <summary>You have to use this function to Asynchronously Execute a given Request</summary>
    /// <param name="AsyncCallbackEvent">The Event that is going to be Executed when the Request finishes.</param>
    /// <param name="ARequest">The request that is going to be Executed</param>
    /// <param name="AContentStream">The stream to store the response data. If provided the user is responsible
    /// of releasing it. If not provided will be created internally and released when not needed.</param>
    /// <param name="AHeaders">Additional Headers to pass to the request that is going to be Executed</param>
    /// <returns>The Asynchronous Result object associated to the given request. It's an Interfaced object and
    /// It's released automatically.</returns>
    function BeginExecute(const AsyncCallbackEvent: TAsyncCallbackEvent; const ARequest: IHTTPRequest;
      const AContentStream: TStream = nil; const AHeaders: TNetHeaders = nil): IHTTPResponse; overload;

    /// <summary>You have to use this function to Wait for the result of a given Asynchronous Request</summary>
    /// <remarks>You must use this class function to ensure that any pending exceptions are raised in the proper context</remarks>
    /// <returns>The platform dependant response object associated to the given request. It's an Interface and It's
    /// released automatically.</returns>
	  class function EndAsyncHTTP(const AAsyncResult: IAsyncResult): IHTTPResponse; overload;
	  class function EndAsyncHTTP(const AAsyncResult: IHTTPResponse): IHTTPResponse; overload;

    /// <summary> Property to manage the Maximum number of redirects when executing a request</summary>
    property MaxRedirects: Integer read GetMaxRedirects write SetMaxRedirects;
    /// <summary> Callback fired when a ClientCertificate is needed</summary>
    property NeedClientCertificateCallback: TNeedClientCertificateCallback read FNeedClientCertificateCallback write FNeedClientCertificateCallback;
    /// <summary> Callback fired when checking the validity of a Server Certificate</summary>
    property ValidateServerCertificateCallback: TValidateCertificateCallback read FValidateServerCertificateCallback write FValidateServerCertificateCallback;

    /// <summary>Property to manage the ReceiveData CallBack</summary>
    property ReceiveDataCallBack: TReceiveDataCallback read FReceiveDataCallback write FReceiveDataCallback;
    /// <summary>Property to manage the ReceiveData Event</summary>
    property OnReceiveData: TReceiveDataEvent read FOnReceiveData write FOnReceiveData;

    /// <summary> Event fired when a ClientCertificate is needed</summary>
    property OnNeedClientCertificate: TNeedClientCertificateEvent read FNeedClientCertificateEvent write FNeedClientCertificateEvent;
    /// <summary> Event fired when checking the validity of a Server Certificate</summary>
    property OnValidateServerCertificate: TValidateCertificateEvent read FValidateServerCertificateEvent write FValidateServerCertificateEvent;
    /// <summary> Cookies policy to be used by the client.</summary>
    /// <remarks>If false the cookies from server will not be accepted,
    /// but the cookies in the cookie manager will be sent.</remarks>
    property AllowCookies: Boolean read FAllowCookies write FAllowCookies;
    /// <summary> Redirection policy to be used by the client.</summary>
    property HandleRedirects: Boolean read FHandleRedirects write FHandleRedirects;

    /// <summary> Cookie manager object to be used by the client.</summary>
    property CookieManager: TCookieManager read FCookieManager write SetCookieManager;

    // Default Request headers properties.
    /// <summary>Property to manage the 'Accept' header</summary>
    property Accept: string read GetAccept write SetAccept;
    /// <summary>Property to manage the 'Accept-CharSet' header</summary>
    property AcceptCharSet: string read GetAcceptCharSet write SetAcceptCharSet;
    /// <summary>Property to manage the 'Accept-Encoding' header</summary>
    property AcceptEncoding: string read GetAcceptEncoding write SetAcceptEncoding;
    /// <summary>Property to manage the 'Accept-Language' header</summary>
    property AcceptLanguage: string read GetAcceptLanguage write SetAcceptLanguage;
    /// <summary>Property to manage the 'Content-Type' header</summary>
    property ContentType: string read GetContentType write SetContentType;
  end;

// -------------------------------------------------------------------------------- //
// -------------------------------------------------------------------------------- //

implementation

uses
{$IFDEF ANDROID}
  System.Net.HttpClient.Android,
  Androidapi.Looper,
  Androidapi.AppGlue,
  Androidapi.NativeActivity,
{$ENDIF ANDROID}
{$IFDEF LINUX}
  System.Net.HttpClient.Linux,
{$ENDIF LINUX}
{$IFDEF MACOS}
  Macapi.CoreFoundation,
  System.Net.HttpClient.Mac,
{$ENDIF MACOS}
{$IFDEF MSWINDOWS}
  System.Net.HttpClient.Win,
{$ENDIF}
  System.ZLib,
  System.DateUtils,
  System.NetConsts,
  System.NetEncoding;


{ THTTPClient }

procedure THTTPClient.Initializer;
begin
  inherited Create;
  FMaxRedirects := DefaultMaxRedirects;
  FHandleRedirects := True;
  FInternalCookieManager := TCookieManager.Create;
  FCookieManager := FInternalCookieManager;
  FAllowCookies := True;
end;

destructor THTTPClient.Destroy;
begin
  FInternalCookieManager.Free;
  inherited;
end;

class function THTTPClient.Create: THTTPClient;
begin
  Result := THTTPClient(TURLSchemes.GetURLClientInstance('HTTP')); // do not translate
end;

class function THTTPClient.EncodingNameToHttpEncodingName(const AEncodingName: string): string;
begin
                                                                                             
  Result := AEncodingName;
end;

class function THTTPClient.EndAsyncHTTP(const AAsyncResult: IAsyncResult): IHTTPResponse;
begin
  (AAsyncResult as TBaseAsyncResult).WaitForCompletion;
  Result := AAsyncResult as IHTTPResponse;
end;

class function THTTPClient.EndAsyncHTTP(const AAsyncResult: IHTTPResponse): IHTTPResponse;
begin
  (AAsyncResult as TBaseAsyncResult).WaitForCompletion;
  Result := AAsyncResult;
end;

function THTTPClient.Execute(const ARequest: IHTTPRequest; const AContentStream: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
var
  LHeader: TNetHeader;
begin
  if AHeaders <> nil then
    for LHeader in AHeaders do
      ARequest.SetHeaderValue(LHeader.Name, LHeader.Value);

  Result := DoGetResponseInstance(Self, nil, nil, nil, ARequest, AContentStream);
  ExecuteHTTP(ARequest, AContentStream, Result);
end;

function THTTPClient.BeginExecute(const ARequest: IHTTPRequest; const AContentStream: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := InternalExecuteAsync(nil, nil, ARequest, AContentStream, AHeaders, False);
end;

function THTTPClient.BeginExecute(const AsyncCallback: TAsyncCallback; const ARequest: IHTTPRequest;
  const AContentStream: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := InternalExecuteAsync(AsyncCallback, nil, ARequest, AContentStream, AHeaders, False);
end;

function THTTPClient.BeginExecute(const AsyncCallbackEvent: TAsyncCallbackEvent; const ARequest: IHTTPRequest;
  const AContentStream: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := InternalExecuteAsync(nil, AsyncCallbackEvent, ARequest, AContentStream, AHeaders, False);
end;

function THTTPClient.InternalExecuteAsync(const AsyncCallback: TAsyncCallback; const AsyncCallbackEvent: TAsyncCallbackEvent;
  const ARequest: IHTTPRequest; const AContentStream: TStream;
  const AHeaders: TNetHeaders; AOwnsSourceStream: Boolean): IHTTPResponse;
var
  LHeader: TNetHeader;
  LContentStream: TStream;
  LAsync: IHTTPResponse;
begin
  if AHeaders <> nil then
    for LHeader in AHeaders do
      ARequest.SetHeaderValue(LHeader.Name, LHeader.Value);

  if AOwnsSourceStream then
    (ARequest as THTTPRequest).FOwnedStream := (ARequest as THTTPRequest).FSourceStream;

  LContentStream := AContentStream;

  LAsync := DoGetResponseInstance(Self,
    procedure
    begin
      ExecuteHTTP(ARequest, LContentStream, LAsync);
    end, AsyncCallback, AsyncCallbackEvent, ARequest, AContentStream);
  Result := LAsync;

  // Invoke Async Execution.
  (LAsync as THttpResponse).Invoke;
end;

procedure THTTPClient.DoNeedClientCertificate(const LRequest: THTTPRequest; const LClientCertificateList: TCertificateList);
var
  LClientCertificateIndex: Integer;
begin
  LClientCertificateIndex := -1;
  if Assigned(FNeedClientCertificateCallback) or Assigned(FNeedClientCertificateEvent) then
  begin
    DoGetClientCertificates(LRequest, LClientCertificateList);
    if LClientCertificateList.Count = 0 then
      raise ENetHTTPCertificateException.CreateRes(@SNetHttpEmptyCertificateList)
    else if Assigned(FNeedClientCertificateCallback) then
      FNeedClientCertificateCallback(Self, LRequest, LClientCertificateList, LClientCertificateIndex)
    else
      FNeedClientCertificateEvent(Self, LRequest, LClientCertificateList, LClientCertificateIndex);
  end;
  if LClientCertificateIndex < 0 then
    raise ENetHTTPCertificateException.CreateRes(@SNetHttpUnspecifiedCertificate)
  else
    if DoClientCertificateAccepted(LRequest, LClientCertificateIndex) = False then
      raise ENetHTTPCertificateException.CreateRes(@SNetHttpRejectedCertificate);
end;

procedure THTTPClient.DoValidateServerCertificate(LRequest: THTTPRequest);
var
  LServerCertAccepted: Boolean;
  LServerCertificate: TCertificate;
begin
  LServerCertAccepted := False;
  if Assigned(FValidateServerCertificateCallback) or Assigned(FValidateServerCertificateEvent) then
  begin
    LServerCertificate := DoGetSSLCertificateFromServer(LRequest);
    if LServerCertificate.Expiry = 0 then
      raise ENetHTTPCertificateException.CreateRes(@SNetHttpGetServerCertificate);
    if Assigned(FValidateServerCertificateCallback) then
      FValidateServerCertificateCallback(Self, LRequest, LServerCertificate, LServerCertAccepted)
    else
      FValidateServerCertificateEvent(Self, LRequest, LServerCertificate, LServerCertAccepted);
  end
  else
    raise ENetHTTPCertificateException.CreateRes(@SNetHttpInvalidServerCertificate);
  if not LServerCertAccepted then
    raise ENetHTTPCertificateException.CreateRes(@SNetHttpServerCertificateNotAccepted)
  else
    DoServerCertificateAccepted(LRequest);
end;

function THTTPClient.Delete(const AURL: string; const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := IHTTPResponse(DoExecute(sHTTPMethodDelete, TURI.Create(AURL), nil, AResponseContent, AHeaders));
end;

function THTTPClient.BeginDelete(const AURL: string; const AResponseContent: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(nil, nil, sHTTPMethodDelete, TURI.Create(AURL), nil, AResponseContent, AHeaders, False);
end;

function THTTPClient.BeginDelete(const AsyncCallback: TAsyncCallback; const AURL: string;
  const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(AsyncCallback, nil, sHTTPMethodDelete, TURI.Create(AURL), nil, AResponseContent, AHeaders, False);
end;

function THTTPClient.BeginDelete(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string;
  const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(nil, AsyncCallbackEvent, sHTTPMethodDelete, TURI.Create(AURL), nil, AResponseContent, AHeaders, False);
end;

function THTTPClient.DoExecute(const ARequestMethod: string; const AURI: TURI; const ASourceStream,
  AContentStream: TStream; const AHeaders: TNetHeaders): IURLResponse;
var
  LRequest: IHTTPRequest;
begin
  LRequest := GetRequest(ARequestMethod, AURI);
  LRequest.SourceStream := ASourceStream;
  Result := Execute(LRequest, AContentStream, AHeaders);
end;

function THTTPClient.DoExecuteAsync(const AsyncCallback: TAsyncCallback; const AsyncCallbackEvent: TAsyncCallbackEvent;
  const ARequestMethod: string; const AURI: TURI; const ASourceStream, AContentStream: TStream;
  const AHeaders: TNetHeaders; AOwnsSourceStream: Boolean): IHTTPResponse;
var
  LRequest: IHTTPRequest;
begin
  LRequest := GetRequest(ARequestMethod, AURI);
  LRequest.SourceStream := ASourceStream;
  Result := InternalExecuteAsync(AsyncCallback, AsyncCallbackEvent, LRequest, AContentStream, AHeaders, AOwnsSourceStream);
end;

procedure THTTPClient.ExecuteHTTPInternal(const ARequest: IHTTPRequest; const AContentStream: TStream; const AResponse: IHTTPResponse);
var
  LRequest: THTTPRequest;
  LResponse: THTTPResponse;
  State: THTTPState;
  LExecResult: TExecutionResult;
  LClientCertificateList: TCertificateList;
  OrigSourceStreamPosition: Int64;
  OrigContentStreamPosition: Int64;
  OrigContentStreamSize: Int64;
  Status: Integer;
  LCookieHeader: string;
begin
  LResponse := AResponse as THTTPResponse;
  LRequest := ARequest as THTTPRequest;
  OrigSourceStreamPosition := 0;
  if LRequest.FSourceStream <> nil then
    OrigSourceStreamPosition := LRequest.FSourceStream.Position;

  if AContentStream <> nil then
  begin
    OrigContentStreamPosition := AContentStream.Position;
    OrigContentStreamSize := AContentStream.Size;
  end
  else
  begin
    OrigContentStreamPosition := 0;
    OrigContentStreamSize := 0;
  end;

  State := Default(THTTPState);
  LClientCertificateList := TCertificateList.Create;
  try
    while True do
    begin
      LRequest.DoPrepare;

      // Add Cookies
      if FCookieManager <> nil then
      begin
        LCookieHeader := FCookieManager.CookieHeaders(LRequest.FURL);
        if LCookieHeader <> '' then
          LRequest.AddHeader('Cookie', LCookieHeader);  // do not localize
      end;

      if not SetServerCredential(LRequest, LResponse, State) then
        Break;
      if not SetProxyCredential(LRequest, LResponse, State) then
        Break;

      if LRequest.FSourceStream <> nil then
        LRequest.FSourceStream.Position := OrigSourceStreamPosition;

      if LResponse <> nil then
      begin
        LResponse.FStream.Position := OrigContentStreamPosition;
        LResponse.FStream.Size := OrigContentStreamSize;
      end;

      LExecResult := DoExecuteRequest(LRequest, LResponse, AContentStream);
      case LExecResult of
        TExecutionResult.Success:
          begin
            if not SameText(LRequest.FMethodString, sHTTPMethodHead) then
              LResponse.DoReadData(LResponse.FStream);
            Status := LResponse.GetStatusCode;
            case Status of
              200:
                begin
                  Break;
                end;
              401:
                begin
                  State.Status := InternalState.ServerAuthRequired;
                end;
              407:
                begin
                  State.Status := InternalState.ProxyAuthRequired;
                end;
              else
                begin
                  case Status of
                    301..304, 307:
                      if FHandleRedirects and (LRequest.FMethodString <> sHTTPMethodHead) then
                      begin
                        Inc(State.Redirections);
                        if State.Redirections > FMaxRedirects then
                          raise ENetHTTPRequestException.CreateResFmt(@SNetHttpMaxRedirections, [FMaxRedirects]);
                      end
                      else
                        Break;
                  else
                  end;
                  State.Status := InternalState.Other;
                  if DoProcessStatus(LRequest, LResponse) then
                    Break;
                end;
            end;
          end;
        TExecutionResult.ServerCertificateInvalid:
          begin
            DoValidateServerCertificate(LRequest);
          end;
        TExecutionResult.ClientCertificateNeeded:
          begin
            DoNeedClientCertificate(LRequest, LClientCertificateList);
          end
        else
          raise ENetHTTPClientException.CreateRes(@SNetHttpClientUnknownError);
      end;

      if AllowCookies then
        UpdateCookiesFromResponse(LResponse);
    end;
    if LRequest.FSourceStream <> nil then
      LRequest.FSourceStream.Seek(0, TSeekOrigin.soEnd);
    LResponse.FStream.Position := OrigContentStreamPosition;
  finally
    LClientCertificateList.Free;
  end;
end;

{$IFDEF ANDROID}
procedure InternalProcessMessages;
var
  PEventPollSource: Pandroid_poll_source;
begin
                                                                                    
  if System.DelphiActivity <> nil then
  begin
    ALooper_pollAll(1, nil, nil, PPointer(@PEventPollSource));
    if (PEventPollSource <> nil) and Assigned(PEventPollSource^.process) then
      PEventPollSource^.process(Pandroid_app(PANativeActivity(System.DelphiActivity)^.instance), PEventPollSource);
  end;
end;
{$ENDIF}

procedure THTTPClient.ExecuteHTTP(const ARequest: IHTTPRequest; const AContentStream: TStream; const AResponse: IHTTPResponse);
{$IFDEF ANDROID}
var
  LTerminated: Boolean;
  LException: Exception;
{$ENDIF}
begin
{$IFNDEF ANDROID} // Not Android
  ExecuteHTTPInternal(ARequest, AContentStream, AResponse);
{$ELSE}
  // Android has a limitation when we are in main thread with http framework. To force the use of http framework in main thread
  // in android we have to change setThreadPolicy, but if you use client certificates the application gets a Force Close
  // Events will not be triggered in main thread so messages are not processed using KeyChain classes
  // To avoid this problem we launch the http request in a thread and we process the messages while the http is processed
  if TThread.CurrentThread.ThreadID = MainThreadID then
  begin
    LTerminated := False;
    LException := nil;
    TThread.CreateAnonymousThread(procedure
      begin
        try
          ExecuteHTTPInternal(ARequest, AContentStream, AResponse);
        except
          on E:Exception do
            LException := E;
        end;
        LTerminated := True;
      end).Start;

    while not LTerminated do
      InternalProcessMessages;

    if LException <> nil then
      raise LException;
  end
  else
    ExecuteHTTPInternal(ARequest, AContentStream, AResponse);
{$ENDIF}
end;

function THTTPClient.DoGetRequestInstance: IURLRequest;
var
  LHeader: TNetHeader;
begin
  Result := DoGetHTTPRequestInstance(Self, sHTTPMethodGet, Default(TURI));
  for LHeader in FCustomHeaders do
    IHTTPRequest(Result).AddHeader(LHeader.Name, LHeader.Value);
end;

function THTTPClient.Get(const AURL: string; const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := IHTTPResponse(DoExecute(sHTTPMethodGet, TURI.Create(AURL), nil, AResponseContent, AHeaders));
end;

function THTTPClient.GetAccept: string;
begin
  Result := GetCustomHeaderValue(sAccept);
end;

function THTTPClient.GetAcceptCharSet: string;
begin
  Result := GetCustomHeaderValue(sAcceptCharset);
end;

function THTTPClient.GetAcceptEncoding: string;
begin
  Result := GetCustomHeaderValue(sAcceptEncoding);
end;

function THTTPClient.GetAcceptLanguage: string;
begin
  Result := GetCustomHeaderValue(sAcceptLanguage);
end;

function THTTPClient.BeginGet(const AsyncCallback: TAsyncCallback; const AURL: string; const AResponseContent: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(AsyncCallback, nil, sHTTPMethodGet, TURI.Create(AURL), nil, AResponseContent, AHeaders, False);
end;

function THTTPClient.BeginGet(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string;
  const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(nil, AsyncCallbackEvent, sHTTPMethodGet, TURI.Create(AURL), nil, AResponseContent, AHeaders, False);
end;

function THTTPClient.BeginGet(const AURL: string; const AResponseContent: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(nil, nil, sHTTPMethodGet, TURI.Create(AURL), nil, AResponseContent, AHeaders, False);
end;

function THTTPClient.GetContentType: string;
begin
  Result := GetCustomHeaderValue(sContentType);
end;

function THTTPClient.GetMaxRedirects: Integer;
begin
  Result := FMaxRedirects;
end;

function THTTPClient.CheckDownloadResume(const AURL: string): Boolean;
var
  LResponse: IHTTPResponse;
  LValue: string;
begin
  LResponse := Head(AURL, [TNetHeader.Create('Range', 'bytes=0-1')]); // do not translate
  if LResponse.StatusCode = 206 then
    Result := True
  else
  begin
    LValue := LResponse.HeaderValue['Accept-Ranges'];
    if (LValue = '') or SameText(LResponse.HeaderValue['Accept-Ranges'], 'none') then  // do not translate
      Result := False
    else
      Result := True;
  end;
end;

function THTTPClient.GetRange(const AURL: string; AStart, AnEnd: Int64; const AResponseContent: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
var
  LHeaders: TNetHeaders;
  LRange: string;
begin
  LRange := 'bytes=';
  if AStart > -1 then
    LRange := LRange + AStart.ToString;
  LRange := LRange + '-';
  if AnEnd > -1 then
    LRange := LRange + AnEnd.ToString;
  LHeaders := AHeaders + [TNetHeader.Create('Range', LRange)]; // do not translate
  Result := Get(AURL, AResponseContent, LHeaders);
end;

function THTTPClient.BeginGetRange(const AURL: string; AStart, AnEnd: Int64; const AResponseContent: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
var
  LHeaders: TNetHeaders;
  LRange: string;
begin
  LRange := 'bytes=';
  if AStart > -1 then
    LRange := LRange + AStart.ToString;
  LRange := LRange + '-';
  if AnEnd > -1 then
    LRange := LRange + AnEnd.ToString;
  LHeaders := AHeaders + [TNetHeader.Create('Range', LRange)]; // do not translate
  Result := BeginGet(AURL, AResponseContent, LHeaders);
end;

function THTTPClient.BeginGetRange(const AsyncCallback: TAsyncCallback; const AURL: string; AStart, AnEnd: Int64;
  const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
var
  LHeaders: TNetHeaders;
  LRange: string;
begin
  LRange := 'bytes=';
  if AStart > -1 then
    LRange := LRange + AStart.ToString;
  LRange := LRange + '-';
  if AnEnd > -1 then
    LRange := LRange + AnEnd.ToString;
  LHeaders := AHeaders + [TNetHeader.Create('Range', LRange)]; // do not translate
  Result := BeginGet(AsyncCallback, AURL, AResponseContent, LHeaders);
end;

function THTTPClient.BeginGetRange(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string; AStart,
  AnEnd: Int64; const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
var
  LHeaders: TNetHeaders;
  LRange: string;
begin
  LRange := 'bytes=';
  if AStart > -1 then
    LRange := LRange + AStart.ToString;
  LRange := LRange + '-';
  if AnEnd > -1 then
    LRange := LRange + AnEnd.ToString;
  LHeaders := AHeaders + [TNetHeader.Create('Range', LRange)]; // do not translate
  Result := BeginGet(AsyncCallbackEvent, AURL, AResponseContent, LHeaders);
end;

function THTTPClient.GetRequest(const ARequestMethod, AURL: string): IHTTPRequest;
begin
  Result := GetRequest(ARequestMethod, TURI.Create(AURL));
end;

function THTTPClient.GetRequest(const ARequestMethod: string; const AURI: TURI): IHTTPRequest;
var
  LRequest: THttpRequest;
  LHeader: TNetHeader;
begin
  if ARequestMethod = '' then
    Result := DoGetHTTPRequestInstance(Self, sHTTPMethodGet, AURI)
  else
    Result := DoGetHTTPRequestInstance(Self, ARequestMethod, AURI);
  for LHeader in FCustomHeaders do
    Result.AddHeader(LHeader.Name, LHeader.Value);
  LRequest := Result as THttpRequest;
  LRequest.FOnReceiveData := FOnReceiveData;
  LRequest.FReceiveDataCallback := FReceiveDataCallback;
end;

function THTTPClient.Head(const AURL: string; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := IHTTPResponse(DoExecute(sHTTPMethodHead, TURI.Create(AURL), nil, nil, AHeaders));
end;

function THTTPClient.BeginHead(const AURL: string; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(nil, nil, sHTTPMethodHead, TURI.Create(AURL), nil, nil, AHeaders, False);
end;

function THTTPClient.BeginHead(const AsyncCallback: TAsyncCallback; const AURL: string;
  const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(AsyncCallback, nil, sHTTPMethodHead, TURI.Create(AURL), nil, nil, AHeaders, False);
end;

function THTTPClient.BeginHead(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string;
  const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(nil, AsyncCallbackEvent, sHTTPMethodHead, TURI.Create(AURL), nil, nil, AHeaders, False);
end;

function THTTPClient.Merge(const AURL: string; const ASource: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := IHTTPResponse(DoExecute(sHTTPMethodMerge, TURI.Create(AURL), ASource, nil, AHeaders));
end;

function THTTPClient.MergeAlternative(const AURL: string; const ASource: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
var
  LHeaders: TNetHeaders;
begin
  LHeaders := [TNetHeader.Create(sXMethodOverride, sHTTPMethodPatch), TNetHeader.Create('PATCHTYPE', sHTTPMethodMerge)] + AHeaders; // Do not translate
  Result := IHTTPResponse(DoExecute(sHTTPMethodPut, TURI.Create(AURL), ASource, nil, LHeaders));
end;

function THTTPClient.BeginMergeAlternative(const AURL: string; const ASource: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
var
  LHeaders: TNetHeaders;
begin
  LHeaders := [TNetHeader.Create(sXMethodOverride, sHTTPMethodPatch), TNetHeader.Create('PATCHTYPE', sHTTPMethodMerge)] + AHeaders; // Do not translate
  Result := DoExecuteAsync(nil, nil, sHTTPMethodPut, TURI.Create(AURL), ASource, nil, LHeaders, False);
end;

function THTTPClient.BeginMergeAlternative(const AsyncCallback: TAsyncCallback; const AURL: string;
  const ASource: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
var
  LHeaders: TNetHeaders;
begin
  LHeaders := [TNetHeader.Create(sXMethodOverride, sHTTPMethodPatch), TNetHeader.Create('PATCHTYPE', sHTTPMethodMerge)] + AHeaders; // Do not translate
  Result := DoExecuteAsync(AsyncCallback, nil, sHTTPMethodPut, TURI.Create(AURL), ASource, nil, LHeaders, False);
end;

function THTTPClient.BeginMergeAlternative(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string;
  const ASource: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
var
  LHeaders: TNetHeaders;
begin
  LHeaders := [TNetHeader.Create(sXMethodOverride, sHTTPMethodPatch), TNetHeader.Create('PATCHTYPE', sHTTPMethodMerge)] + AHeaders; // Do not translate
  Result := DoExecuteAsync(nil, AsyncCallbackEvent, sHTTPMethodPut, TURI.Create(AURL), ASource, nil, LHeaders, False);
end;

function THTTPClient.BeginMerge(const AURL: string; const ASource: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(nil, nil, sHTTPMethodMerge, TURI.Create(AURL), ASource, nil, AHeaders, False);
end;

function THTTPClient.BeginMerge(const AsyncCallback: TAsyncCallback; const AURL: string; const ASource: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(AsyncCallback, nil, sHTTPMethodMerge, TURI.Create(AURL), ASource, nil, AHeaders, False);
end;

function THTTPClient.BeginMerge(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string;
  const ASource: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(nil, AsyncCallbackEvent, sHTTPMethodMerge, TURI.Create(AURL), ASource, nil, AHeaders, False);
end;

function THTTPClient.Options(const AURL: string; const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := IHTTPResponse(DoExecute(sHTTPMethodOptions, TURI.Create(AURL), nil, AResponseContent, AHeaders));
end;

function THTTPClient.BeginOptions(const AURL: string; const AResponseContent: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(nil, nil, sHTTPMethodOptions, TURI.Create(AURL), nil, AResponseContent, AHeaders, False);
end;

function THTTPClient.BeginOptions(const AsyncCallback: TAsyncCallback; const AURL: string;
  const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(AsyncCallback, nil, sHTTPMethodOptions, TURI.Create(AURL), nil, AResponseContent, AHeaders, False);
end;

function THTTPClient.BeginOptions(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string;
  const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(nil, AsyncCallbackEvent, sHTTPMethodOptions, TURI.Create(AURL), nil, AResponseContent, AHeaders, False);
end;

function THTTPClient.Patch(const AURL: string; const ASource, AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := IHTTPResponse(DoExecute(sHTTPMethodPatch, TURI.Create(AURL), ASource, AResponseContent, AHeaders));
end;

function THTTPClient.PatchAlternative(const AURL: string; const ASource, AResponseContent: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
var
  LHeaders: TNetHeaders;
begin
  LHeaders := [TNetHeader.Create(sXMethodOverride, sHTTPMethodPatch)] + AHeaders;
  Result := IHTTPResponse(DoExecute(sHTTPMethodPut, TURI.Create(AURL), ASource, AResponseContent, LHeaders));
end;

function THTTPClient.BeginPatchAlternative(const AURL: string; const ASource, AResponseContent: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
var
  LHeaders: TNetHeaders;
begin
  LHeaders := [TNetHeader.Create(sXMethodOverride, sHTTPMethodPatch)] + AHeaders;
  Result := DoExecuteAsync(nil, nil, sHTTPMethodPut, TURI.Create(AURL), ASource, AResponseContent, LHeaders, False);
end;

function THTTPClient.BeginPatchAlternative(const AsyncCallback: TAsyncCallback; const AURL: string; const ASource,
  AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
var
  LHeaders: TNetHeaders;
begin
  LHeaders := [TNetHeader.Create(sXMethodOverride, sHTTPMethodPatch)] + AHeaders;
  Result := DoExecuteAsync(AsyncCallback, nil, sHTTPMethodPut, TURI.Create(AURL), ASource, AResponseContent, LHeaders, False);
end;

function THTTPClient.BeginPatchAlternative(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string;
  const ASource, AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
var
  LHeaders: TNetHeaders;
begin
  LHeaders := [TNetHeader.Create(sXMethodOverride, sHTTPMethodPatch)] + AHeaders;
  Result := DoExecuteAsync(nil, AsyncCallbackEvent, sHTTPMethodPut, TURI.Create(AURL), ASource, AResponseContent, LHeaders, False);
end;

function THTTPClient.BeginPatch(const AURL: string; const ASource, AResponseContent: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(nil, nil, sHTTPMethodPatch, TURI.Create(AURL), ASource, AResponseContent, AHeaders, False);
end;

function THTTPClient.BeginPatch(const AsyncCallback: TAsyncCallback; const AURL: string; const ASource,
  AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(AsyncCallback, nil, sHTTPMethodPatch, TURI.Create(AURL), ASource, AResponseContent, AHeaders, False);
end;

function THTTPClient.BeginPatch(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string; const ASource,
  AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(nil, AsyncCallbackEvent, sHTTPMethodPatch, TURI.Create(AURL), ASource, AResponseContent, AHeaders, False);
end;

function THTTPClient.Post(const AURL: string; const ASource: TStrings; const AResponseContent: TStream;
  const AEncoding: TEncoding; const AHeaders: TNetHeaders): IHTTPResponse;
var
  LSourceStream: TStringStream;
  LParams: string;
  LHeaders: TNetHeaders;
  LEncodingName: string;
  LEncoding: TEncoding;
  I: Integer;
  Pos: Integer;
begin
  LParams := '';
  for I := 0 to ASource.Count - 1 do
  begin
    Pos := ASource[I].IndexOf('=');
    if Pos > 0 then
      LParams := LParams + TNetEncoding.URL.EncodeForm(ASource[I].Substring(0, Pos)) + '=' + TNetEncoding.URL.EncodeForm(ASource[I].Substring(Pos + 1)) + '&';
  end;
  if (LParams <> '') and (LParams[High(LParams)] = '&') then
    LParams := LParams.Substring(0, LParams.Length - 1); // Remove last &

  if AEncoding = nil then
  begin
    LEncoding := TEncoding.UTF8;
    LEncodingName := 'UTF-8'; // do not localize
  end
  else
  begin
    LEncoding := AEncoding;
    LEncodingName := AEncoding.EncodingName;
  end;
  LEncodingName := EncodingNameToHttpEncodingName(LEncodingName);
  LSourceStream := TStringStream.Create(LParams, LEncoding, False);
  try
    LHeaders := [TNetHeader.Create(sContentType, 'application/x-www-form-urlencoded; charset=' + LEncodingName)] + AHeaders;  // do not translate
    Result := IHTTPResponse(DoExecute(sHTTPMethodPost, TURI.Create(AURL), LSourceStream, AResponseContent, LHeaders));
  finally
    LSourceStream.Free;
  end;
end;

function THTTPClient.Post(const AURL: string; const ASource, AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := IHTTPResponse(DoExecute(sHTTPMethodPost, TURI.Create(AURL), ASource, AResponseContent, AHeaders));
end;

function THTTPClient.Post(const AURL: string; const ASourceFile: string; const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
var
  LSourceStream: TStream;
begin
  LSourceStream := TFileStream.Create(ASourceFile, fmOpenRead);
  try
    Result := IHTTPResponse(DoExecute(sHTTPMethodPost, TURI.Create(AURL), LSourceStream, AResponseContent, AHeaders));
  finally
    LSourceStream.Free;
  end;
end;

function THTTPClient.Post(const AURL: string; const ASource: TMultipartFormData;
  const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
var
  LRequest: IHTTPRequest;
begin
  LRequest := GetRequest(sHTTPMethodPost, AURL);
  LRequest.SourceStream := ASource.Stream;
  LRequest.SourceStream.Position := 0;
  LRequest.AddHeader(sContentType, ASource.MimeTypeHeader);
  Result := Execute(LRequest, AResponseContent, AHeaders);
end;

function THTTPClient.BeginPost(const AURL: string; const ASource: TMultipartFormData; const AResponseContent: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
var
  LRequest: IHTTPRequest;
begin
  LRequest := GetRequest(sHTTPMethodPost, AURL);
  LRequest.SourceStream := ASource.Stream;
  LRequest.SourceStream.Position := 0;
  LRequest.AddHeader(sContentType, ASource.MimeTypeHeader);
  Result := BeginExecute(LRequest, AResponseContent, AHeaders);
end;

function THTTPClient.BeginPost(const AsyncCallback: TAsyncCallback; const AURL: string;
  const ASource: TMultipartFormData; const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
var
  LRequest: IHTTPRequest;
begin
  LRequest := GetRequest(sHTTPMethodPost, AURL);
  LRequest.SourceStream := ASource.Stream;
  LRequest.SourceStream.Position := 0;
  LRequest.AddHeader(sContentType, ASource.MimeTypeHeader);
  Result := BeginExecute(AsyncCallback, LRequest, AResponseContent, AHeaders);
end;

function THTTPClient.BeginPost(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string;
  const ASource: TMultipartFormData; const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
var
  LRequest: IHTTPRequest;
begin
  LRequest := GetRequest(sHTTPMethodPost, AURL);
  LRequest.SourceStream := ASource.Stream;
  LRequest.SourceStream.Position := 0;
  LRequest.AddHeader(sContentType, ASource.MimeTypeHeader);
  Result := BeginExecute(AsyncCallbackEvent, LRequest, AResponseContent, AHeaders);
end;

function THTTPClient.BeginPost(const AURL: string; const ASource: TStrings; const AResponseContent: TStream;
  const AEncoding: TEncoding; const AHeaders: TNetHeaders): IHTTPResponse;
var
  LParams: string;
  LHeaders: TNetHeaders;
  LEncodingName: string;
  LEncoding: TEncoding;
  I: Integer;
  Pos: Integer;
begin
  LParams := '';
  for I := 0 to ASource.Count - 1 do
  begin
    Pos := ASource[I].IndexOf('=');
    if Pos > 0 then
      LParams := LParams + TNetEncoding.URL.EncodeForm(ASource[I].Substring(0, Pos)) + '=' + TNetEncoding.URL.EncodeForm(ASource[I].Substring(Pos + 1)) + '&';
  end;
  if (LParams <> '') and (LParams[High(LParams)] = '&') then
    LParams := LParams.Substring(0, LParams.Length - 1); // Remove last &

  if AEncoding = nil then
  begin
    LEncoding := TEncoding.UTF8;
    LEncodingName := 'UTF-8'; // do not localize
  end
  else
  begin
    LEncoding := AEncoding;
    LEncodingName := AEncoding.EncodingName;
  end;
  LEncodingName := EncodingNameToHttpEncodingName(LEncodingName);
  LHeaders := [TNetHeader.Create(sContentType, 'application/x-www-form-urlencoded; charset=' + LEncodingName)] + AHeaders;  // do not translate

  Result := DoExecuteAsync(nil, nil, sHTTPMethodPost, TURI.Create(AURL), TStringStream.Create(LParams, LEncoding, False),
    AResponseContent, LHeaders, True);
end;

function THTTPClient.BeginPost(const AsyncCallback: TAsyncCallback; const AURL: string; const ASource: TStrings;
  const AResponseContent: TStream; const AEncoding: TEncoding; const AHeaders: TNetHeaders): IHTTPResponse;
var
  LParams: string;
  LHeaders: TNetHeaders;
  LEncodingName: string;
  LEncoding: TEncoding;
  I: Integer;
  Pos: Integer;
begin
  LParams := '';
  for I := 0 to ASource.Count - 1 do
  begin
    Pos := ASource[I].IndexOf('=');
    if Pos > 0 then
      LParams := LParams + TNetEncoding.URL.EncodeForm(ASource[I].Substring(0, Pos)) + '=' + TNetEncoding.URL.EncodeForm(ASource[I].Substring(Pos + 1)) + '&';
  end;
  if (LParams <> '') and (LParams[High(LParams)] = '&') then
    LParams := LParams.Substring(0, LParams.Length - 1); // Remove last &

  if AEncoding = nil then
  begin
    LEncoding := TEncoding.UTF8;
    LEncodingName := 'UTF-8'; // do not localize
  end
  else
  begin
    LEncoding := AEncoding;
    LEncodingName := AEncoding.EncodingName;
  end;
  LEncodingName := EncodingNameToHttpEncodingName(LEncodingName);
  LHeaders := [TNetHeader.Create(sContentType, 'application/x-www-form-urlencoded; charset=' + LEncodingName)] + AHeaders;  // do not translate

  Result := DoExecuteAsync(AsyncCallback, nil, sHTTPMethodPost, TURI.Create(AURL), TStringStream.Create(LParams, LEncoding, False), AResponseContent, LHeaders, True);
end;

function THTTPClient.BeginPost(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string;
  const ASource: TStrings; const AResponseContent: TStream; const AEncoding: TEncoding;
  const AHeaders: TNetHeaders): IHTTPResponse;
var
  LParams: string;
  LHeaders: TNetHeaders;
  LEncodingName: string;
  LEncoding: TEncoding;
  I: Integer;
  Pos: Integer;
begin
  LParams := '';
  for I := 0 to ASource.Count - 1 do
  begin
    Pos := ASource[I].IndexOf('=');
    if Pos > 0 then
      LParams := LParams + TNetEncoding.URL.EncodeForm(ASource[I].Substring(0, Pos)) + '=' + TNetEncoding.URL.EncodeForm(ASource[I].Substring(Pos + 1)) + '&';
  end;
  if (LParams <> '') and (LParams[High(LParams)] = '&') then
    LParams := LParams.Substring(0, LParams.Length - 1); // Remove last &

  if AEncoding = nil then
  begin
    LEncoding := TEncoding.UTF8;
    LEncodingName := 'UTF-8'; // do not localize
  end
  else
  begin
    LEncoding := AEncoding;
    LEncodingName := AEncoding.EncodingName;
  end;
  LEncodingName := EncodingNameToHttpEncodingName(LEncodingName);
  LHeaders := [TNetHeader.Create(sContentType, 'application/x-www-form-urlencoded; charset=' + LEncodingName)] + AHeaders;  // do not translate

  Result := DoExecuteAsync(nil, AsyncCallbackEvent, sHTTPMethodPost, TURI.Create(AURL), TStringStream.Create(LParams, LEncoding, False), AResponseContent, LHeaders, True);
end;

function THTTPClient.BeginPost(const AURL, ASourceFile: string; const AResponseContent: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(nil, nil, sHTTPMethodPost, TURI.Create(AURL), TFileStream.Create(ASourceFile, fmOpenRead),
    AResponseContent, AHeaders, True);
end;

function THTTPClient.BeginPost(const AsyncCallback: TAsyncCallback; const AURL, ASourceFile: string;
  const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(AsyncCallback, nil, sHTTPMethodPost, TURI.Create(AURL),
    TFileStream.Create(ASourceFile, fmOpenRead), AResponseContent, AHeaders, True);
end;

function THTTPClient.BeginPost(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL, ASourceFile: string;
  const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(nil, AsyncCallbackEvent, sHTTPMethodPost, TURI.Create(AURL),
    TFileStream.Create(ASourceFile, fmOpenRead), AResponseContent, AHeaders, True);
end;

function THTTPClient.BeginPost(const AURL: string; const ASource, AResponseContent: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(nil, nil, sHTTPMethodPost, TURI.Create(AURL), ASource, AResponseContent, AHeaders, False);
end;

function THTTPClient.BeginPost(const AsyncCallback: TAsyncCallback; const AURL: string; const ASource,
  AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(AsyncCallback, nil, sHTTPMethodPost, TURI.Create(AURL), ASource, AResponseContent, AHeaders, False);
end;

function THTTPClient.BeginPost(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string; const ASource,
  AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(nil, AsyncCallbackEvent, sHTTPMethodPost, TURI.Create(AURL), ASource, AResponseContent, AHeaders, False);
end;

function THTTPClient.Put(const AURL: string; const ASource, AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := IHTTPResponse(DoExecute(sHTTPMethodPut, TURI.Create(AURL), ASource, AResponseContent, AHeaders));
end;

function THTTPClient.BeginPut(const AURL: string; const ASource, AResponseContent: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(nil, nil, sHTTPMethodPut, TURI.Create(AURL), ASource, AResponseContent, AHeaders, False);
end;

function THTTPClient.BeginPut(const AsyncCallback: TAsyncCallback; const AURL: string; const ASource,
  AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(AsyncCallback, nil, sHTTPMethodPut, TURI.Create(AURL), ASource, AResponseContent, AHeaders, False);
end;

function THTTPClient.BeginPut(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string; const ASource,
  AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(nil, AsyncCallbackEvent, sHTTPMethodPut, TURI.Create(AURL), ASource, AResponseContent, AHeaders, False);
end;

procedure THTTPClient.SetAccept(const Value: string);
begin
  SetCustomHeaderValue(sAccept, Value);
end;

procedure THTTPClient.SetAcceptCharSet(const Value: string);
begin
  SetCustomHeaderValue(sAcceptCharset, Value);
end;

procedure THTTPClient.SetAcceptEncoding(const Value: string);
begin
  SetCustomHeaderValue(sAcceptEncoding, Value);
end;

procedure THTTPClient.SetAcceptLanguage(const Value: string);
begin
  SetCustomHeaderValue(sAcceptLanguage, Value);
end;

procedure THTTPClient.SetContentType(const Value: string);
begin
  SetCustomHeaderValue(sContentType, Value);
end;

procedure THTTPClient.SetCookieManager(const Value: TCookieManager);
begin
{$IFNDEF AUTOREFCOUNT}
  FInternalCookieManager.Free;
{$ENDIF AUTOREFCOUNT}
  FInternalCookieManager := nil;
  FCookieManager := Value;
  if FCookieManager = nil then
    AllowCookies := False;
end;

procedure THTTPClient.SetMaxRedirects(const Value: Integer);
begin
  FMaxRedirects := Value;
end;

function THTTPClient.SetProxyCredential(const ARequest: THTTPRequest; const AResponse: THTTPResponse;
  var State: THTTPClient.THTTPState): Boolean;
var
  LAbortAuth: Boolean;
  LPersistence: TAuthPersistenceType;
  OldPass: string;
  OldUser: string;
begin
  Result := True;
  LPersistence := TAuthPersistenceType.Client;

  if State.Status = InternalState.ProxyAuthRequired then
  begin
    if State.ProxyCredential.UserName = '' then
    // It's the first Proxy auth request
    begin
      if ProxySettings.Host <> '' then
        State.ProxyCredentials := [ProxySettings.Credential]
      else
        State.ProxyCredentials := [];
      State.ProxyCredentials := State.ProxyCredentials + GetCredentials(TAuthTargetType.Proxy,
        AResponse.InternalGetAuthRealm, '');
      State.NeedProxyCredential := True;
    end;
  end;
  if State.NeedProxyCredential then
  begin
    if State.Status = InternalState.ProxyAuthRequired then
    begin
      if State.ProxyIterator < Length(State.ProxyCredentials) then
      begin   // Get the next credential from the storage
        State.ProxyCredential.AuthTarget := TAuthTargetType.Proxy;
        State.ProxyCredential.UserName := State.ProxyCredentials[State.ProxyIterator].UserName;
        State.ProxyCredential.Password := State.ProxyCredentials[State.ProxyIterator].Password;
        Inc(State.ProxyIterator);
      end
      else
      begin
        //Can't get a valid proxy credential from the storage so ask to the user
        LAbortAuth := False;
        State.ProxyCredential.AuthTarget := TAuthTargetType.Proxy;
        OldUser := State.ProxyCredential.UserName;
        OldPass := State.ProxyCredential.Password;
        State.ProxyCredential.UserName := '';
        State.ProxyCredential.Password := '';
        DoAuthCallback(TAuthTargetType.Proxy, AResponse.InternalGetAuthRealm, ARequest.GetURL.ToString,
          State.ProxyCredential.UserName, State.ProxyCredential.Password, LAbortAuth, LPersistence);
        if (State.ProxyCredential.Password = '') or LAbortAuth then
          State.ProxyCredential.UserName := '';
        if State.ProxyCredential.UserName <> '' then
        begin
          // If it is the same user and password than the previous one we empty the given and abort the operation to avoid infinite loops.
          if (State.ProxyCredential.UserName = OldUser) and (State.ProxyCredential.Password = OldPass) then
            State.ProxyCredential.UserName := ''
          else
            if LPersistence = TAuthPersistenceType.Client then
              CredentialsStorage.AddCredential(State.ProxyCredential);
        end;
      end;
    end;
    if State.ProxyCredential.UserName <> '' then
      Result := DoSetCredential(TAuthTargetType.Proxy, ARequest, State.ProxyCredential)
    else
      Result := False;  // We need a Credential but we haven't found a good one, so exit
  end;
end;

function THTTPClient.SetServerCredential(const ARequest: THTTPRequest; const AResponse: THTTPResponse;
  var State: THTTPClient.THTTPState): Boolean;
var
  LAbortAuth: Boolean;
  LPersistence: TAuthPersistenceType;
  OldPass: string;
  OldUser: string;
begin
  Result := True;
  LPersistence := TAuthPersistenceType.Client;
  // Set Server Credentials
  if State.Status = InternalState.ServerAuthRequired then
  begin
    if State.ServerCredential.UserName = '' then
    // It's the first Server auth request
    begin
      State.ServerCredentials := GetCredentials(TAuthTargetType.Server, AResponse.InternalGetAuthRealm,
        ARequest.GetURL.ToString);
      if ARequest.GetCredential.UserName <> '' then
        State.ServerCredentials := [ARequest.GetCredential] + State.ServerCredentials;
      State.NeedServerCredential := True;
    end;
  end;
  if State.NeedServerCredential then
  begin
    if State.Status = InternalState.ServerAuthRequired then
    begin
      if State.ServerIterator < Length(State.ServerCredentials) then
      begin  // Get the next credential from the storage
        State.ServerCredential.AuthTarget := TAuthTargetType.Server;
        State.ServerCredential.UserName := State.ServerCredentials[State.ServerIterator].UserName;
        State.ServerCredential.Password := State.ServerCredentials[State.ServerIterator].Password;
        State.ServerCredential.Realm := State.ServerCredentials[State.ServerIterator].Realm;
        Inc(State.ServerIterator);
      end
      else
      begin
        //Can't get a valid server credential from the storage so ask to the user
        LAbortAuth := False;
        State.ServerCredential.AuthTarget := TAuthTargetType.Server;
        OldUser := State.ServerCredential.UserName;
        OldPass := State.ServerCredential.Password;
        State.ServerCredential.UserName := '';
        State.ServerCredential.Password := '';
        State.ServerCredential.Realm := AResponse.InternalGetAuthRealm;
        DoAuthCallback(TAuthTargetType.Server, AResponse.InternalGetAuthRealm, ARequest.GetURL.ToString,
          State.ServerCredential.UserName, State.ServerCredential.Password, LAbortAuth, LPersistence);
        if (State.ServerCredential.Password = '') or LAbortAuth then
          State.ServerCredential.UserName := '';
        if State.ServerCredential.UserName <> '' then
        begin
          // If it is the same user and password than the previous one we empty the given and abort the operation to avoid infinite loops.
          if (State.ServerCredential.UserName = OldUser) and (State.ServerCredential.Password = OldPass) then
            State.ServerCredential.UserName := ''
          else
            if LPersistence = TAuthPersistenceType.Client then
              CredentialsStorage.AddCredential(State.ServerCredential);
        end;
      end;
    end;
    if State.ServerCredential.UserName <> '' then
      Result := DoSetCredential(TAuthTargetType.Server, ARequest, State.ServerCredential)
    else
      Result := False;  // We need a Credential but we haven't found a good one, so exit
  end;
end;

function THTTPClient.SupportedSchemes: TArray<string>;
begin
  Result := ['HTTP', 'HTTPS']; // Do not translate
end;

function THTTPClient.Trace(const AURL: string; const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := IHTTPResponse(DoExecute(sHTTPMethodTrace, TURI.Create(AURL), nil, AResponseContent, AHeaders));
end;

function THTTPClient.BeginTrace(const AURL: string; const AResponseContent: TStream;
  const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(nil, nil, sHTTPMethodTrace, TURI.Create(AURL), nil, AResponseContent, AHeaders, False);
end;

function THTTPClient.BeginTrace(const AsyncCallback: TAsyncCallback; const AURL: string;
  const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(AsyncCallback, nil, sHTTPMethodTrace, TURI.Create(AURL), nil, AResponseContent, AHeaders, False);
end;

function THTTPClient.BeginTrace(const AsyncCallbackEvent: TAsyncCallbackEvent; const AURL: string;
  const AResponseContent: TStream; const AHeaders: TNetHeaders): IHTTPResponse;
begin
  Result := DoExecuteAsync(nil, AsyncCallbackEvent, sHTTPMethodTrace, TURI.Create(AURL), nil, AResponseContent, AHeaders, False);
end;

procedure THTTPClient.UpdateCookiesFromResponse(const AResponse: THTTPResponse);
var
  I: Integer;
begin
  for I := 0 to AResponse.FCookies.Count -1 do
    FCookieManager.AddServerCookie(AResponse.FCookies[I], AResponse.FRequest.URL);
end;

{ THTTPRequest }

constructor THTTPRequest.Create(const AClient: THTTPClient; const ARequestMethod: string; const AURI: TURI);
begin
  inherited Create(AClient, ARequestMethod, AURI);
end;

destructor THTTPRequest.Destroy;
begin
  FOwnedStream.Free;
  inherited;
end;

procedure THTTPRequest.DoReceiveDataProgress(AStatusCode: Integer; AContentLength, AReadCount: Int64; var Abort: Boolean);
begin
  if AStatusCode < 300 then
    if Assigned(FReceiveDataCallback) then
      FReceiveDataCallback(Self, AContentLength, AReadCount, Abort)
    else if Assigned(FOnReceiveData) then
      FOnReceiveData(Self, AContentLength, AReadCount, Abort);
end;

function THTTPRequest.GetAccept: string;
begin
  Result := GetHeaderValue(sAccept);
end;

function THTTPRequest.GetAcceptCharSet: string;
begin
  Result := GetHeaderValue(sAcceptCharset);
end;

function THTTPRequest.GetAcceptEncoding: string;
begin
  Result := GetHeaderValue(sAcceptEncoding);
end;

function THTTPRequest.GetAcceptLanguage: string;
begin
  Result := GetHeaderValue(sAcceptLanguage);
end;

function THTTPRequest.GetClientCertificate: TStream;
begin
  Result := FClientCertificate;
end;

function THTTPRequest.GetReceiveDataCallback: TReceiveDataCallback;
begin
  Result := FReceiveDataCallback;
end;

function THTTPRequest.GetReceiveDataEvent: TReceiveDataEvent;
begin
  Result := FOnReceiveData;
end;

function THTTPRequest.GetUserAgent: string;
begin
  Result := GetHeaderValue(sUserAgent);
end;

procedure THTTPRequest.SetAccept(const Value: string);
begin
  SetHeaderValue(sAccept, Value);
end;

procedure THTTPRequest.SetAcceptCharSet(const Value: string);
begin
  SetHeaderValue(sAcceptCharset, Value);
end;

procedure THTTPRequest.SetAcceptEncoding(const Value: string);
begin
  SetHeaderValue(sAcceptEncoding, Value);
end;

procedure THTTPRequest.SetAcceptLanguage(const Value: string);
begin
  SetHeaderValue(sAcceptLanguage, Value);
end;

procedure THTTPRequest.SetClientCertificate(const Value: TStream; const Password: string);
begin
  FClientCertificate := Value;
  FClientCertPassword := Password;
end;

procedure THTTPRequest.SetReceiveDataCallback(const Value: TReceiveDataCallback);
begin
  FReceiveDataCallback := Value;
end;

procedure THTTPRequest.SetReceiveDataEvent(const Value: TReceiveDataEvent);
begin
  FOnReceiveData := Value;
end;

procedure THTTPRequest.SetUserAgent(const Value: string);
begin
  SetHeaderValue(sUserAgent, Value);
end;

{ THTTPResponse }

procedure THTTPResponse.InternalAddCookie(const ACookieData: string);
begin
  FCookies.Add(TCookie.Create(ACookieData, FRequest.URL));
end;

function THTTPResponse.ContainsHeader(const AName: string): Boolean;
begin
  Result := GetHeaderValue(AName) <> '';
end;

function THTTPResponse.ContentAsString(const AnEncoding: TEncoding): string;
var
  LReader: TStringStream;
  LCharset: string;
  LStream: TStream;
  LFreeLStream: Boolean;
begin
  Result := '';
  if AnEncoding = nil then
  begin
    LCharset := GetContentCharset;
    if (LCharSet <> '') and (string.CompareText(LCharSet, 'utf-8') <> 0) then  // do not translate
      LReader := TStringStream.Create('', TEncoding.GetEncoding(LCharSet), True)
    else
      LReader := TStringStream.Create('', TEncoding.UTF8, False);
  end
  else
    LReader := TStringStream.Create('', AnEncoding, False);
  try
    //rizzato
    {$IF defined(MSWINDOWS) or defined(ANDROID)}
    if GetContentEncoding = 'gzip' then
    begin
      // 15 is the default mode.
      // 16 is to enable gzip mode.  http://www.zlib.net/manual.html#Advanced
      LStream := TDecompressionStream.Create(FStream, 15 + 16);
      LFreeLStream := True;
    end
    else
    {$ENDIF}
    begin
      LStream := FStream;
      LFreeLStream := False;
    end;

    try
      LReader.CopyFrom(LStream, 0);
      Result := LReader.DataString;
    finally
      if LFreeLStream then
       LStream.Free;
    end;
  finally
    LReader.Free;
  end;
end;

constructor THTTPResponse.Create(const AContext: TObject; const AProc: TProc;
  const AAsyncCallback: TAsyncCallback; const AAsyncCallbackEvent: TAsyncCallbackEvent;
  const ARequest: IHTTPRequest; const AContentStream: TStream);
begin
  inherited Create(AContext, AProc, AAsyncCallBack, AAsyncCallbackEvent, AContentStream);
  FRequest := ARequest;
  SetLength(FHeaders, 0);
  FCookies := TCookies.Create;
end;

destructor THTTPResponse.Destroy;
begin
  FCookies.Free;
  FInternalStream.Free;
  inherited;
end;

function THTTPResponse.GetContentCharSet: string;
var
  LCharSet: string;
  LSplitted: TArray<string>;
  LValues: TArray<string>;
  S: string;
begin
  Result := '';
  LCharSet := GetHeaderValue(sContentType);
  LSplitted := LCharset.Split([';']);
  for S in LSplitted do
  begin
    if S.TrimLeft.StartsWith('charset', True) then // do not translate
    begin
      LValues := S.Split(['=']);
      if Length(LValues) = 2 then
        Result := LValues[1].Trim.DeQuotedString.DeQuotedString('"');
      Break;
    end;
  end;
end;

function THTTPResponse.GetContentEncoding: string;
begin
  Result := GetHeaderValue(sContentEncoding);
end;

function THTTPResponse.GetContentLanguage: string;
begin
  Result := GetHeaderValue(sContentLanguage);
end;

function THTTPResponse.GetContentLength: Int64;
begin
  Result := StrToInt64Def(GetHeaderValue(sContentLength), -1);
end;

function THTTPResponse.GetContentStream: TStream;
begin
  Result := FStream;
end;

function THTTPResponse.GetCookies: TCookies;
begin
  Result := FCookies;
end;

function THTTPResponse.GetDate: string;
begin
  Result := GetHeaderValue('Date'); // do not translate
end;

function THTTPResponse.GetHeaderValue(const AName: string): string;
var
  I: Integer;
  LHeaders: TNetHeaders;
begin
  Result := '';
  LHeaders := GetHeaders;
  for I := 0 to Length(LHeaders) - 1 do
  begin
    if string.CompareText(AName, LHeaders[I].Name) = 0 then
    begin
      Result := LHeaders[I].Value;
      Break;
    end;
  end;
end;

function THTTPResponse.GetLastModified: string;
begin
  Result := GetHeaderValue(sLastModified);
end;

function THTTPResponse.GetMimeType: string;
begin
  Result := GetHeaderValue(sContentType);
end;

function THTTPResponse.InternalGetAuthRealm: string;
var
  LValue: string;
  Pos: Integer;
  LLower: string;
begin
  LValue := GetHeaderValue(sWWWAuthenticate);
  if LValue = '' then
    LValue := GetHeaderValue(sProxyAuthenticate);

  if LValue = '' then
    Result := ''
  else
  begin
    LLower := LValue.ToLower;
    Pos := LLower.IndexOf('realm="') + Length('realm="'); // Do not translate
    Result := LValue.Substring(Pos, LLower.IndexOf('"', Pos + 1) - Pos);
  end;
end;

{ TCookieManager }

constructor TCookieManager.Create;
begin
  FCookies := TCookies.Create;
end;

procedure TCookieManager.DeleteExpiredCookies;
var
  I: Integer;
begin
  for I := FCookies.Count - 1 downto 0 do
    if (FCookies[I].Expires <> 0) and (FCookies[I].Expires < Now) then
      FCookies.Delete(I);
end;

destructor TCookieManager.Destroy;
begin
  FCookies.Free;
  inherited;
end;

function TCookieManager.GetCookies: TCookiesArray;
begin
  DeleteExpiredCookies;
  Result := FCookies.ToArray;
end;

procedure TCookieManager.AddServerCookie(const ACookieData, ACookieURL: string);
var
  LURI: TURI;
  Values: TArray<string>;
  I: Integer;
begin
  if ACookieURL = '' then
    LURI := Default(TURI)
  else
    LURI := TURI.Create(ACookieURL);

  Values := ACookieData.Split([Char(',')], Char('"'));
  for I := 0 to High(Values) do
    AddServerCookie(TCookie.Create(Values[I], LURI), LURI);
end;

procedure TCookieManager.AddServerCookie(const ACookie: TCookie; const AURL: TURI);
begin
  if ValidCookie(ACookie, AURL) then
    UpdateCookie(ACookie, AURL);
end;

function TCookieManager.CookieHeaders(const AURI: TURI): string;
var
  I: Integer;
begin
  Result := '';
  if FCookies.Count > 0 then
  begin
    TMonitor.Enter(FCookies);
    try
      DeleteExpiredCookies;
      for I := FCookies.Count - 1 downto 0 do
      begin
        if not FCookies[I].Secure or (FCookies[I].Secure and SameText(AURI.Scheme, 'https')) then  // do not localize
          Result := Result + FCookies[I].ToString + '; ';
      end;
    finally
      TMonitor.Exit(FCookies);
    end;
    if Result <> '' then
      Result := Result.Substring(0, Result.Length - 2); // remove last ;
  end;
end;

procedure TCookieManager.UpdateCookie(const ACookie: TCookie; const AURL: TURI);
var
  I: Integer;
  Found: Boolean;
begin
  TMonitor.Enter(FCookies);
  try
    Found := False;
    DeleteExpiredCookies;
    for I := 0 to FCookies.Count - 1 do
    begin
      if SameText(ACookie.Name, FCookies[I].Name) and
         SameText(ACookie.Domain, FCookies[I].Domain) and
         SameText(ACookie.Path, FCookies[I].Path) then
      begin
        Found := True;
        FCookies[I] := ACookie;
        Break;
      end
    end;
    if not Found and ((ACookie.Expires = 0) or (ACookie.Expires > Now)) then
      FCookies.Add(ACookie);
  finally
    TMonitor.Exit(FCookies);
  end;
end;

function TCookieManager.ValidCookie(const ACookie: TCookie; const AURL: TURI): Boolean;
begin
  Result := ('.' + AURL.Host).EndsWith(ACookie.Domain) and AURL.Path.StartsWith(ACookie.Path);
end;

{ TCookie }

// RFC 6265 section 5.1.1  http://tools.ietf.org/html/rfc6265#page-14
class function TCookie.StrExpiresToDateTime(const AStrDate: string): TDateTime;
var
  LDate: TDateTime;
  LTime: TDateTime;
  Pos: Integer;
  Len: Integer;
  LFoundTime: Boolean;
  LFoundDayOfMonth: Boolean;
  LFoundMonth: Boolean;
  LFoundYear: Boolean;
  LHours: Integer;
  LMinutes: Integer;
  LSeconds: Integer;
  LYear: Integer;
  LMonth: Integer;
  LDayOfMonth: Integer;
  Token: string;

  function IsDelimiter(C: Char): Boolean;
  //delimiter = %x09 / %x20-2F / %x3B-40 / %x5B-60 / %x7B-7E
  begin
    case C of
      Char($09), Char($20)..Char($2F), Char($3B)..Char($40), Char($5B)..Char($60), Char($7B)..Char($7E): Result := True;
    else
      Result := False;
    end;
  end;

  function IsNonDelimiter(C: Char): Boolean;
  //non-delimiter = %x00-08 / %x0A-1F / DIGIT / ":" / ALPHA / %x7F-FF
  begin
    case C of
      Char($00)..Char($08), Char($0A)..Char($1F), '0'..'9', ':', 'A'..'Z', 'a'..'z', Char($7F)..Char($FF): Result := True;
    else
      Result := False;
    end;
  end;

  procedure CleanDelimiters;
  begin
    while (Pos < Len) and IsDelimiter(AStrDate.Chars[Pos]) do
      Inc(Pos);
  end;

  function ReadToken: string;
  begin
    Result := '';
    while (Pos < Len) and IsNonDelimiter(AStrDate.Chars[Pos]) do
    begin
      Result := Result + AStrDate.Chars[Pos];
      Inc(Pos);
    end;
  end;

  function CheckTime: Boolean;
  const
    HoursPart = 0;
    MinutesPart = 1;
    SecondsPart = 2;
  var
    Parts: TArray<string>;
  begin
    Result := False;
    if not LFoundTime then
    begin
      Parts := Token.Split([Char(':')]);
      if Length(Parts) = 3 then
      begin
        if (Parts[HoursPart].Length = 1) or (Parts[HoursPart].Length = 2) then
          if not TryStrToInt(Parts[HoursPart], LHours) or (LHours > 23) then
            Exit;

        if (Parts[MinutesPart].Length = 1) or (Parts[MinutesPart].Length = 2) then
          if not TryStrToInt(Parts[MinutesPart], LMinutes) or (LMinutes > 59) then
            Exit;

        if (Parts[SecondsPart].Length = 1) or (Parts[SecondsPart].Length = 2) then
          if not TryStrToInt(Parts[SecondsPart], LSeconds) or (LSeconds > 59) then
            Exit;

        LFoundTime := True;
        Result := True;
      end;
    end;
  end;

  function CheckDayOfMonth: Boolean;
  begin
    Result := False;
    if not LFoundDayOfMonth then
    begin
      if (Token.Length = 1) or (Token.Length = 2) then
        if TryStrToInt(Token, LDayOfMonth) and (LDayOfMonth >= 1) and (LDayOfMonth <= 31) then
        begin
          LFoundDayOfMonth := True;
          Result := True;
        end;
    end;
  end;

  function CheckMonth: Boolean;
  const
    Months: array[1..12] of string = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');  // do not localize
  var
    I: Integer;
  begin
    Result := False;
    if not LFoundMonth then
    begin
      for I := 1 to 12 do
        if SameText(Token, Months[I]) then
        begin
          LMonth := I;
          LFoundMonth := True;
          Result := True;
          Break;
        end;
    end;
  end;

  function CheckYear: Boolean;
  begin
    Result := False;
    if not LFoundYear then
    begin
      if (Token.Length = 2) or (Token.Length = 4) then
        if TryStrToInt(Token, LYear) then
        begin
          if (LYear >= 70) and (LYear <= 99) then
            LYear := LYear + 1900
          else
            if (LYear >= 0) and (LYear <= 69) then
              LYear := LYear + 2000;

          if LYear > 1600 then
          begin
            LFoundYear := True;
            Result := True;
          end;
        end;
    end;
  end;

begin
  LFoundTime := False;
  LFoundDayOfMonth := False;
  LFoundMonth := False;
  LFoundYear := False;
  Pos := 0;
  Len := AStrDate.Length;

  while Pos < Len do
  begin
    CleanDelimiters;
    Token := ReadToken;

    if CheckTime then
      Continue;

    if CheckDayOfMonth then
      Continue;

    if CheckMonth then
      Continue;

    if CheckYear then
      Continue;

    if LFoundTime and LFoundDayOfMonth and LFoundMonth and LFoundYear then
      Break;
  end;

  if LFoundTime and LFoundDayOfMonth and LFoundMonth and LFoundYear then
  begin
    if TryEncodeDate(LYear, LMonth, LDayOfMonth, LDate) and TryEncodeTime(LHours, LMinutes, LSeconds, 0, LTime) then
    begin
      LDate := LDate + LTime;
      Result := TTimeZone.Local.ToLocalTime(LDate);
      if Result = 0 then // To avoid to create a session cookie if the expire date is in the delphi date limit
        Result := 1;
    end
    else
      Result := 0;
  end
  else
    Result := 0;
end;

class function TCookie.Create(const ACookieData: string; const AURI: TURI): TCookie;

  procedure SetExpires(const AValue: string);
  begin
    if Result.Expires = 0 then
      Result.Expires := StrExpiresToDateTime(AValue);
  end;

  procedure SetMaxAge(const AValue: string);
  var
    Increment: Integer;
  begin
    if TryStrToInt(AValue, Increment) then
      Result.Expires := IncSecond(Now, Increment);
  end;

  procedure SetPath(const AValue: string);
  begin
    if (AValue = '') or (AValue[High(AValue)] <> '/') then
      Result.Path := AValue + '/'
    else
      Result.Path := AValue;
  end;

  procedure SetDomain(const AValue: string);
  begin
    if (AValue <> '') and (AValue.Chars[0] <> '.') then
      Result.Domain := '.' + AValue
    else
      Result.Domain := AValue;
  end;
var
  Values: TArray<string>;
  I: Integer;
  Pos: Integer;
  LName: string;
  LValue: string;
begin
  Result := Default(TCookie);
  Values := ACookieData.Split([Char(';')], Char('"'));
  if Length(Values) = 0 then
    Exit(Default(TCookie));

  Pos := Values[0].IndexOf(Char('='));
  if Pos <= 0 then
    Exit(Default(TCookie));
  Result.Name := TNetEncoding.URL.Decode(Values[0].Substring(0, Pos).Trim, [TURLEncoding.TDecodeOption.PlusAsSpaces]);
  Result.Value := TNetEncoding.URL.Decode(Values[0].Substring(Pos + 1).Trim, [TURLEncoding.TDecodeOption.PlusAsSpaces]);
  Result.Path := '/';
  Result.Domain := '.' + AURI.Host;

  for I := 1 to High(Values) do
  begin
    Pos := Values[I].IndexOf(Char('='));
    if Pos > 0 then
    begin
      LName := Values[I].Substring(0, Pos).Trim;
      LValue := Values[I].Substring(Pos + 1).Trim;
      if (LValue.Length > 1) and (LValue.Chars[0] = '"') and (LValue[High(LValue)] = '"') then
        LValue := LValue.Substring(1, LValue.Length - 2);
    end
    else
    begin
      LName := Values[I].Trim;
      LValue := '';
    end;

    if SameText(LName, 'Max-Age') then  // Do not translate
      SetMaxAge(LValue)
    else if SameText(LName, 'Expires') then  // Do not translate
      SetExpires(LValue)
    else if SameText(LName, 'Path') then  // Do not translate
      SetPath(LValue)
    else if SameText(LName, 'Domain') then // Do not translate
      SetDomain(LValue)
    else if SameText(LName, 'HttpOnly') then  // Do not translate
      Result.HttpOnly := True
    else if SameText(LName, 'Secure') then  // Do not translate
      Result.Secure := True;
  end;
end;

function TCookie.ToString: string;
begin
  Result := TNetEncoding.URL.EncodeForm(Name) + '=' + TNetEncoding.URL.EncodeForm(Value);
end;

end.
