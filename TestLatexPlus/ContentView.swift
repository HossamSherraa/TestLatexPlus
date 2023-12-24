
import SwiftUI
import WebKit

import SwiftUI
import WebKit

import SwiftUI
import WebKit
import PDFKit

struct MathJaxView: UIViewRepresentable {
    let latex: String
    @Binding var renderedSize: CGFloat?

    func makeUIView(context: Context) -> WKWebView {
        let webViewConfiguration = WKWebViewConfiguration()

        // Add a user content controller to handle JavaScript messages
        let userContentController = WKUserContentController()
        
        userContentController.add(context.coordinator, name: "getSize")
        webViewConfiguration.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false 
        
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let mathJaxHeader = """
            <head>
                <script type="text/x-mathjax-config">
                    MathJax.Hub.Config({
                        showMathMenu: false,
                        messageStyle: "none",
                        CommonHTML: { linebreaks: { automatic: true } },
                        "HTML-CSS": {
                            linebreaks: { automatic: true }
                        }
                    });
                </script>
                <script type="text/javascript" async
                    src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.7/MathJax.js?config=TeX-MML-AM_CHTML">
                </script>
                <style>
                    body {
                        font-size: 43px;
                        color: black;
                    }
                </style>
            </head>
            """

        let htmlString = """
            <html>
                \(mathJaxHeader)
                <body>
                    <span id="mathjaxContent">\(latex)</span>
                    <script>
                        // Function to get the height of the rendered MathJax content
                        function getHeight() {
                            var height = document.getElementById('mathjaxContent').offsetHeight;
                            window.webkit.messageHandlers.getSize.postMessage({ height: height });
                        }

                        // Configure MathJax
                        MathJax.Hub.Config({
                            tex2jax: {
                                inlineMath: [['\\(', '\\)']],
                                displayMath: [['$$', '$$']],
                                processEscapes: true
                            },
                            messageStyle: 'none',
                            showMathMenu: false
                        });

                        // Typeset the math content
                        MathJax.Hub.Queue(["Typeset", MathJax.Hub, "mathjaxContent", function () {
                            // Call the getHeight function after rendering is complete
                            getHeight();
                        }]);
                    </script>
                </body>
            </html>
            """

        uiView.loadHTMLString(htmlString, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: MathJaxView

        init(parent: MathJaxView) {
            self.parent = parent
        }

      
            func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1 ) {
                    self.resizePDF(webView: webView)
                    
                }
                  
               }
            
        

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            print(message.body)
             
        }
        
        func resizePDF(webView : WKWebView){
           webView.createPDF { data -> Void in
               
               try! self.resizePDF(data: data.get())
            }
        }
        
        func resizePDF(data : Data){
            let x = URL.applicationDirectory.appending(path: "12.pdf")
            let page = try! PDFDocument(data: data)!.page(at: 0)!
            let selection = page.selection(from: .zero, to: .init(x: page.bounds(for: .mediaBox).width, y: page.bounds(for: .mediaBox).height))
            print(selection!.bounds(for: page))
            try? data.write(to: x)
            
        }
    }
    
    
}

struct ContentView : View {
  @State var size: CGFloat?
   
  var body: some View {
    MathJaxView(latex: latexExample, renderedSize: $size)
      .border(Color.black)
       
      .onAppear {
        size = nil // Reset the state to ensure recalculation if the content changes
      }
  }
}

let latexExample = #"""
To solve the quadratic equation \(2x^2 + 5x - 3 = 0\), we can use the quadratic formula: $$x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$$ where \(a\), \(b\), and \(c\) are the coefficients of the quadratic equation. In this case, \(a = 2\), \(b = 5\), and \(c = -3\). Substituting



"""#
