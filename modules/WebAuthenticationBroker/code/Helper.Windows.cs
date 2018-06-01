using System;
using System.Collections;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Navigation;

namespace PSWebAuthBroker_ab8baa5cebae4693a6fc517d7b0f69c3
{
    public class BrokerWindow : IDisposable
    {
        Window window;
        WebBrowser browser;

        /// <summary>
        /// Initializes a new BrokerWindow object.
        /// </summary>
        public BrokerWindow()
        {
            window = new Window();
            browser = new WebBrowser();
            browser.Tag = this;
            browser.Navigating += browserNavigating;
            browser.Navigated += browserNavigated;
            window.Tag = this;
            window.Title = "Authnetication Broker";
            window.MinWidth = 440;
            window.MinHeight = 330;
            window.Width = 550;
            window.Height = 450;
            window.Content = browser;
            window.Closing += windowClosing;
        }

        /// <summary>
        /// Displays the broker and authenticates the user. This method must not be called twice.
        /// </summary>
        public bool AuthenticateUser()
        {
            browser.Navigate(InitialUri);
            return window.ShowDialog() == true;
        }

        /// <summary>
        /// Gets/sets the title for the window.
        /// </summary>
        public string Title { get { return window.Title; } set { window.Title = value; } }

        /// <summary>
        /// Gets/sets the initial URI to navigate to.
        /// </summary>
        public string InitialUri { get; set; }

        /// <summary>
        /// Gets/sets whether the broker should use current URI as the title.
        /// </summary>
        public bool TitleIsUri { get; set; }

        /// <summary>
        /// Gets the extracted information object.
        /// </summary>
        public object Extracted { get; private set; }

        /// <summary>
        /// Gets/sets an extractor delegate that extracts authentication information from the URI.
        /// This delegate is called each time the broker has navigated.
        /// Returning null from this delegate continues the authentication procedure.
        /// Returning non-null from this delegate terminates the authentication procedure.
        /// </summary>
        public Func<string, object> CompletionExtractor { get; set; }

        /// <summary>
        /// Gets/sets a predicate whether a URI should be allowed to display within this broker.
        /// This delegate is called each time before the broker navigates.
        /// Returning true from this delegate allows navigation.
        /// Returning false from this delegate disallows navigation.
        /// An example usage is to only allow HTTPS pages.
        /// </summary>
        public Func<string, bool> UriPredicate { get; set; }

        private static void browserNavigating(object sender, NavigatingCancelEventArgs e)
        {
            var that = (BrokerWindow)((WebBrowser)sender).Tag;
            var uriUri = e.Uri;
            var uri = (uriUri != null ? uriUri.AbsoluteUri : null);
            var pred = that.UriPredicate ?? (_ => true);
            if (!pred(uri))
            {
                MessageBox.Show(that.window,
                    "The URI is disallowed in this authentication broker.\r\nThe URI is " + uri,
                    "Navigation cancelled",
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning);
                e.Cancel = true;
            }
        }
        
        const BindingFlags InstancePublicMethod = BindingFlags.Instance | BindingFlags.Public | BindingFlags.InvokeMethod;
        const BindingFlags InstancePublicSetProp = BindingFlags.Instance | BindingFlags.Public | BindingFlags.SetProperty;
        static readonly object[] CreateScriptElementParams = new object[] { "SCRIPT" };
        static readonly object[] SetTypeJSParams = new object[] { "application/javascript" };
        static readonly object[] SetInnerHtmlJSParams = new object[] { "window.onerror = function () { return true; };" };
        static readonly object[] GetHeadParams = new object[] { "head" };

        private static void SuppressJavaScriptErrors(WebBrowser browser)
        {
            try
            {
                var doc = browser.Document;
                var scriptElement = doc.GetType().InvokeMember("createElement", InstancePublicMethod,
                    null, doc, CreateScriptElementParams);
                scriptElement.GetType().InvokeMember("type", InstancePublicSetProp,
                    null, scriptElement, SetTypeJSParams);
                scriptElement.GetType().InvokeMember("innerHTML", InstancePublicSetProp,
                    null, scriptElement, SetInnerHtmlJSParams);
                var heads = doc.GetType().InvokeMember("getElementsByTagName", InstancePublicMethod,
                    null, doc, GetHeadParams);
                foreach (var head in (IEnumerable)heads)
                {
                    head.GetType().InvokeMember("appendChild", InstancePublicMethod,
                        null, head, new object[] { scriptElement });
                    break;
                }
            }
            catch { }
        }

        private static void browserNavigated(object sender, NavigationEventArgs e)
        {
            var that = (BrokerWindow)((WebBrowser)sender).Tag;
            SuppressJavaScriptErrors(that.browser);
            var srcUri = that.browser.Source;
            var newSource = (srcUri != null ? srcUri.AbsoluteUri : null);
            if (that.TitleIsUri)
            {
                that.window.Title = newSource ?? "Authentication Broker";
            }
            var extractor = that.CompletionExtractor ?? (_ => null);
            var extracted = extractor(newSource ?? "");
            if (!ReferenceEquals(extracted, null))
            {
                that.Extracted = extracted;
                that.window.DialogResult = true;
                that.window.Close();
            }
        }

        private static void windowClosing(object sender, System.ComponentModel.CancelEventArgs e)
        {
            var that = (BrokerWindow)((Window)sender).Tag;
            that.Dispose();
        }

        /// <summary>
        /// Disposes the object.
        /// This method is automatically called when the UI is dismissed.
        /// </summary>
        public void Dispose()
        {
            window.Content = null;
            browser.Dispose();
        }
    }
}
