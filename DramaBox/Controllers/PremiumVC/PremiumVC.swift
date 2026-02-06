//
//  PremiumVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 28/01/26.
//

import UIKit
import StoreKit
import SafariServices
import SVProgressHUD

enum Products: String, CaseIterable {
    case porno_yearly = "YearlyBase"
    case porno_monthly = "MonthlyBase"
}
protocol DismissPremium {
    func dismiss(_ isExit: Bool)
}

class PremiumVC: UIViewController, SKProductsRequestDelegate {

    @IBOutlet weak var addFreeLbl: UILabel!
    @IBOutlet weak var upcomingLbl: UILabel!
    @IBOutlet weak var shortsLbl: UILabel!
    @IBOutlet weak var monthlyPlanLbl: UILabel!
    @IBOutlet weak var onlyMonthLbl: UILabel!
    @IBOutlet weak var monthlyLbl: UILabel!
    @IBOutlet weak var monthPremiumButton: UIButton!
    @IBOutlet weak var yearPremiumButton: UIButton!
    @IBOutlet weak var onlyYearLbl: UILabel!
    @IBOutlet weak var yearlyLbl: UILabel!
    @IBOutlet weak var yearlyPlanLbl: UILabel!
    @IBOutlet weak var eulaButton: UIButton!
    @IBOutlet weak var termsButton: UIButton!
    @IBOutlet weak var privacyButton: UIButton!
    @IBOutlet weak var restoreButton: UIButton!
    @IBOutlet weak var yearlyPriceLbl: UILabel!
    @IBOutlet weak var monthlyPriceLbl: UILabel!
    @IBOutlet weak var getPremiumLbl: UILabel!
    @IBOutlet weak var unlockLbl: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var models = [SKProduct]()
    var selectedIndex: Int = 0
    var delegate: DismissPremium?
    private var gradientLayer: CAGradientLayer?
    var isIpad = UIDevice.current.isPad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        SKPaymentQueue.default().add(self)
        fetchInAppProduct()
        setLoca()
    }
    func setUI() {
        if isIpad {
        } else {
        }
    }
    func setLoca() {
        getPremiumLbl.text = "Get Premium Access".localized(LocalizationService.shared.language)
        unlockLbl.text = "Unlock premium benefits for a better experience".localized(LocalizationService.shared.language)
        addFreeLbl.text = "Ad-free experience".localized(LocalizationService.shared.language)
        upcomingLbl.text = "Upcoming movie details".localized(LocalizationService.shared.language)
        shortsLbl.text = "Short reels from great films".localized(LocalizationService.shared.language)
        monthlyPlanLbl.text = "Monthly Plan".localized(LocalizationService.shared.language)
        onlyMonthLbl.text = "Only".localized(LocalizationService.shared.language)
        monthlyLbl.text = "/Monthly".localized(LocalizationService.shared.language)
        monthPremiumButton.setTitle("Unlock Premium".localized(LocalizationService.shared.language), for: .normal)
        yearlyPlanLbl.text = "Yearly Plan".localized(LocalizationService.shared.language)
        onlyYearLbl.text = "Only".localized(LocalizationService.shared.language)
        yearlyLbl.text = "/Yearly".localized(LocalizationService.shared.language)
        yearPremiumButton.setTitle("Unlock Premium".localized(LocalizationService.shared.language), for: .normal)
        eulaButton.setTitle("EULA".localized(LocalizationService.shared.language), for: .normal)
        termsButton.setTitle("Terms".localized(LocalizationService.shared.language), for: .normal)
        privacyButton.setTitle("Privacy".localized(LocalizationService.shared.language), for: .normal)
        restoreButton.setTitle("Restore".localized(LocalizationService.shared.language), for: .normal)
        cancelButton.setTitle("Cancel".localized(LocalizationService.shared.language), for: .normal)
    }
    private func fetchInAppProduct() {
        let request  = SKProductsRequest(productIdentifiers: Set(Products.allCases.compactMap({$0.rawValue})))
        request.delegate = self
        request.start()
        SVProgressHUD.dismiss()
    }
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            print("Count:\(response.products)")
            let count = response.products.count
            if count == 0 {
                self.scrollView.isHidden = true
            } else {
                self.scrollView.isHidden = false
            }
            self.models = response.products
            self.models.sort { $0.price.doubleValue > $1.price.doubleValue }
            WebServices().ProgressViewHide(uiView: self.view)
            
            self.updatePriceLabels()
        }
    }
    private func updatePriceLabels() {
        guard models.count >= 2 else { return }
        
        // Yearly product should be first (higher price)
        let yearlyProduct = models[0]
        let monthlyProduct = models[1]
        
        // Update Yearly Plan Labels
        yearlyPriceLbl.text = "\(yearlyProduct.priceLocale.currencySymbol ?? "$")\(yearlyProduct.price)"
        
        // Update Monthly Plan Labels
        monthlyPriceLbl.text = "\(monthlyProduct.priceLocale.currencySymbol ?? "$")\(monthlyProduct.price)"
    }
    private func startPurchaseProcess() {
        if SKPaymentQueue.canMakePayments() {
            if models.count > 0 {
                SVProgressHUD.show()
                let payment = SKPayment(product: models[selectedIndex])
                SKPaymentQueue.default().add(payment)
            }
        }
        SVProgressHUD.dismiss()
    }
}
// MARK: - Button Action's
extension PremiumVC {
    @IBAction func backButtonTap(_ sender: UIButton) {
        self.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.dismiss(true)
        }
    }
    
    @IBAction func monthlyPremiumButtonTap(_ sender: UIButton) {
        self.selectedIndex = 1
        startPurchaseProcess()
    }
    
    @IBAction func yearlyPremiumButtonTap(_ sender: UIButton) {
        self.selectedIndex = 0
        startPurchaseProcess()
    }
    
    @IBAction func restorePremiumButtonTap(_ sender: UIButton) {
        SVProgressHUD.show()
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
        SVProgressHUD.dismiss()
    }
    
    @IBAction func privacyButonTap(_ sender: UIButton) {
        if let url = URL(string: "\(AppConstant.privacyPolicyURL)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    @IBAction func termsButtonTap(_ sender: UIButton) {
        if let url = URL(string: "\(AppConstant.tremsOfUseURL)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    @IBAction func eulaButtonTap(_ sender: UIButton) {
        if let url = URL(string: "\(AppConstant.EULA)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}
//MARK: - SKPaymentTransactionObserver
extension PremiumVC : SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        //imp
        
        transactions.forEach({
            switch $0.transactionState {
            case .purchasing:
                print("purchasing")
            case .purchased:
                print("purchased")
                
                SKPaymentQueue.default().finishTransaction($0)
                Subscribe.save(true)
                UserDefaults.standard.synchronize()
                NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
                WebServices().ProgressViewHide(uiView: self.view)
//                HelperManager.showRateScreen(navigation: self)
                self.dismiss(animated: true)
                
            case .failed:
                print("failed")
                SKPaymentQueue.default().finishTransaction($0)
                WebServices().ProgressViewHide(uiView: self.view)

                // Optional: If you already show this alert, you may want to remove one to avoid double alerts
                showAlertMsg(
                    Message: "Failed your transaction, please try again!",
                    AutoHide: false
                )

                let failed = UIAlertController(
                    title: "Purchase Stopped",
                    message: "Either you cancelled the request or Apple reported a transaction error. Please try again later, or contact the app's customer support for assistance.",
                    preferredStyle: .alert
                )

                // ✅ OK button
                let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                    print("User tapped OK")
                }

                // Add button to alert
                failed.addAction(okAction)

                // ❌ This line looks unrelated to alert, keep only if really needed
                // HelperManager.showRateScreen(navigation: self)

                // Present alert
                self.present(failed, animated: true, completion: nil)
                
            case .restored:
                print("restored")
                
                WebServices().ProgressViewHide(uiView: self.view)
                Subscribe.save(true)
                UserDefaults.standard.synchronize()
                NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
                WebServices().ProgressViewHide(uiView: self.view)
            case .deferred:
                break
            @unknown default:
                break
            }
        })
        
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        // Restore completed transactions failed
        // You can handle any necessary error handling or display an error message to the user
        print("Restore completed transactions failed with error: \(error.localizedDescription)")
        let restore = UIAlertController(title: "No Subscription to Restore", message: "You don't have an active subscription.", preferredStyle: .alert)
        restore.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        self.present(restore, animated: true, completion: nil)
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        // Restore completed transactions finished successfully
        // You can handle any necessary logic here, such as updating UI or displaying a success message
        print("Restore completed transactions finished successfully")
        for transaction in queue.transactions {
            if (transaction.original?.payment.productIdentifier) != nil {
                // Restore the productIdentifier and mark the subscription as active
                Subscribe.save(true)
                UserDefaults.standard.synchronize()
                NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
                let restore = UIAlertController(title: "Restore", message: "Subscription Restored Successfully!", preferredStyle: .alert)
                restore.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                    self.dismiss(animated: false)
                }))
                
                self.present(restore, animated: true, completion: nil)
            } else {
                let restore = UIAlertController(title: "No Subscription to Restore", message: "You don't have an active subscription.", preferredStyle: .alert)
                restore.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                
                self.present(restore, animated: true, completion: nil)
            }
        }
        
        if queue.transactions.isEmpty == true {
            let restore = UIAlertController(title: "No Subscription to Restore", message: "You don't have an active subscription.", preferredStyle: .alert)
            restore.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            self.present(restore, animated: true, completion: nil)
        }
    }
}
