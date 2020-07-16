import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

const String examplepage = '''
      <!DOCTYPE html><html>
      <head><title>Navigation Delegate Example</title></head>
      <body>
     <iframe width="654" height="374" src="https://www.youtube.com/embed/3azDg_tU30k" frameborder="0"
    allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
      </body>
      </html>
      ''';

class AdvencedWebViewExample extends StatefulWidget {
  @override
  _AdvencedWebViewExampleState createState() => _AdvencedWebViewExampleState();
}

JavascriptChannel snackbarJavascriptChannel(BuildContext context) {
  return JavascriptChannel(
      name: 'SnackbarJSChannel',
      onMessageReceived: (JavascriptMessage message) {
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text(message.message),
        ));
      });
}

class _AdvencedWebViewExampleState extends State<AdvencedWebViewExample> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Advenced Web view"),
        actions: <Widget>[
          NavigationControls(_controller.future),
          SampleMenu(_controller.future)
        ],
      ),
      body: Builder(builder: (BuildContext context) {
        return WebView(
          initialUrl: 'http://flutter.dev',
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            _controller.complete(webViewController);
          },
          javascriptChannels: <JavascriptChannel>[
            snackbarJavascriptChannel(context),
          ].toSet(),
          navigationDelegate: (NavigationRequest request) {
            if (request.url.startsWith("https://www.youtube.com")) {
              print("Blocking navigation");
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        );
      }),
    );
  }
}

enum MenuOptions {
  showUserAgent,
  listCookies,
  clearCookies,
  addToCache,
  listCache,
  clearCache,
  navigationDelegate,
}

class SampleMenu extends StatelessWidget {
  SampleMenu(this.controller);
  final Future<WebViewController> controller;
  final CookieManager cookieManager = CookieManager();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: controller,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> controller) {
        return PopupMenuButton<MenuOptions>(
          itemBuilder: (BuildContext context) => <PopupMenuItem<MenuOptions>>[
            PopupMenuItem(
                child: const Text("Show User Agent"),
                value: MenuOptions.showUserAgent,
                enabled: controller.hasData),
            PopupMenuItem(
              child: const Text("List Cookies"),
              value: MenuOptions.listCookies,
            ),
            PopupMenuItem(
              child: const Text("Clear Cookies"),
              value: MenuOptions.clearCookies,
            ),
            PopupMenuItem(
              child: const Text("Add to Cache"),
              value: MenuOptions.addToCache,
            ),
            PopupMenuItem(
              child: const Text("List Cache"),
              value: MenuOptions.listCache,
            ),
            PopupMenuItem(
              child: const Text("Clear Cache"),
              value: MenuOptions.clearCache,
            ),
            PopupMenuItem(
              child: const Text("Navigation Delegate Demo"),
              value: MenuOptions.navigationDelegate,
            ),
          ],
          onSelected: (MenuOptions value) {
            switch (value) {
              case MenuOptions.showUserAgent:
                showUserAgent(controller.data, context);
                break;
              case MenuOptions.listCookies:
                listCookies(controller.data, context);
                break;
              case MenuOptions.clearCookies:
                clearCookies(controller.data, context);
                break;
              case MenuOptions.addToCache:
                addToCache(controller.data, context);
                break;
              case MenuOptions.listCache:
                listCache(controller.data, context);
                break;
              case MenuOptions.clearCache:
                clearCache(controller.data, context);
                break;
              case MenuOptions.navigationDelegate:
                navigationDelegateDemo(controller.data, context);
                break;
              default:
            }
          },
        );
      },
    );
  }

  navigationDelegateDemo(
      WebViewController controller, BuildContext context) async {
    final String contentbase64 =
        base64Encode(const Utf8Encoder().convert(examplepage));
    controller.loadUrl('data:text/html;base64,$contentbase64');
  }

  void listCache(WebViewController controller, BuildContext context) async {
    await controller.evaluateJavascript(
        'caches.keys().then((cacheKeys) => JSON.stringify({"cacheKeys": cacheKeys,"localStorage":localStorage})).then((caches) => SnackbarJSChannel.postMessage(caches))');
  }

  void clearCache(WebViewController controller, BuildContext context) async {
    await controller.clearCache();
    Scaffold.of(context)
        .showSnackBar(const SnackBar(content: Text("Cache Cleared")));
  }

  addToCache(WebViewController controller, BuildContext context) async {
    await controller.evaluateJavascript(
        'caches.open("test_caches_entry"); localStorage["test_localStorage"] = "dummy_entry" ;');
    Scaffold.of(context).showSnackBar(const SnackBar(
      content: Text("Added a test entry to cache"),
    ));
  }

  listCookies(WebViewController controller, BuildContext context) async {
    final String cookies =
        await controller.evaluateJavascript('document.cookie');
    Scaffold.of(context).showSnackBar(SnackBar(
        content: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[const Text("Cookies:"), getCookies(cookies)],
    )));
  }

  Widget getCookies(String cookies) {
    if (cookies == null || cookies.isEmpty) {
      return Container();
    }
    final List<String> cookieList = cookies.split(';');
    final Iterable<Text> cookieWidgets =
        cookieList.map((String cookie) => Text(cookie));
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: cookieWidgets.toList(),
    );
  }

  void clearCookies(WebViewController controller, BuildContext context) async {
    final bool hadCookies = await cookieManager.clearCookies();
    String message = 'There are no cookies';
    Scaffold.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  showUserAgent(WebViewController controller, BuildContext context) {
    controller.evaluateJavascript(
        'SnackbarJSChannel.postMessage("User Agent: " + navigator.userAgent);');
  }
}

class NavigationControls extends StatelessWidget {
  const NavigationControls(this._webViewControllerFuture);
  final Future<WebViewController> _webViewControllerFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _webViewControllerFuture,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> snapshot) {
        final bool webViewReady =
            snapshot.connectionState == ConnectionState.done;
        final WebViewController controller = snapshot.data;
        return Row(
          children: <Widget>[
            IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: !webViewReady
                    ? null
                    : () async {
                        if (await controller.canGoBack()) {
                          controller.goBack();
                        } else {
                          Scaffold.of(context).showSnackBar(const SnackBar(
                              content: Text("No Back history Item")));
                        }
                      }),
            IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: !webViewReady
                    ? null
                    : () async {
                        if (await controller.canGoForward()) {
                          controller.goForward();
                        } else {
                          Scaffold.of(context).showSnackBar(const SnackBar(
                              content: Text("No Forward history Item")));
                        }
                      }),
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: !webViewReady
                    ? null
                    : () async {
                        controller.reload();
                      }),
          ],
        );
      },
    );
  }
}
