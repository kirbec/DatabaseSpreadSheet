//
//  InfoDetailViewController.swift
//  DatabaseSpreadsheet
//
//  Created by Alex Drewno on 12/23/18.
//  Copyright © 2018 Alex Drewno. All rights reserved.
//

import Foundation
import UIKit
import CoreData

// MARK: - ViewController Properties
class InfoDetailViewController: UIViewController {

    @IBOutlet weak var infoTableView: UITableView!
    @IBOutlet weak var totalCostLabel: UILabel!
    @IBOutlet weak var estimateCostLabel: UILabel!
    var estimateTotal: Double = 0
    var actualTotal: Double = 0
    var new: Bool = false
    var infoSpreadsheet: InfoSpreadsheet!
    var curNum: Int = 0 {
        didSet {
            self.title = "Invoice #\(curNum)"
        }
    }

    override func viewDidLoad() {
        infoTableView.dataSource = self
        infoTableView.delegate = self
        setupUI()
        super.viewDidLoad()
    }

    func updateTotalLabels() {
        estimateTotal = 0
        actualTotal = 0

        for sectionRow in infoSpreadsheet?.sections?.array as? [InfoProductSection] ?? [] {
            for infoProduct in sectionRow.infoProducts?.array as? [InfoProduct] ?? [] {
                estimateTotal += infoProduct.estimateTotal
                actualTotal += infoProduct.asBuiltTotal
            }
        }

        estimateCostLabel.text = "Estimate Cost: $\(estimateTotal)"
        totalCostLabel.text = "Total Cost: $\(actualTotal)"
    }
}

// MARK: - TableView Properties
extension InfoDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 40))
        headerView.backgroundColor = UIColor(red: 249/255, green: 249/255, blue: 249/255, alpha: 1)
        headerView.layer.borderWidth = 1.5
        headerView.layer.borderColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor
        let sectionLabel = UILabel(frame: CGRect(x: headerView.center.x,
                                                y: headerView.center.y,
                                                width: self.view.bounds.width,
                                                height: 40))
        sectionLabel.textAlignment = NSTextAlignment.center
        sectionLabel.center = headerView.center
        var objectArray: [InfoProductSection] = infoSpreadsheet?.sections?.array as? [InfoProductSection] ?? []
        sectionLabel.text = "\(objectArray[section].name ?? "")"
        sectionLabel.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.medium)
        sectionLabel.textColor = UIColor.black

        headerView.addSubview(sectionLabel)
        return headerView
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        let sectionsCount = infoSpreadsheet?.sections?.count ?? 0

        if sectionsCount == 0 {
            infoTableView.separatorStyle = .none
        } else {
            infoTableView.separatorStyle = .singleLine
        }

        return sectionsCount
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let objectArray = infoSpreadsheet?.sections?.array as? [InfoProductSection] ?? []
        if objectArray == [] {
            return 1
        }
        return ((objectArray[section].infoProducts?.count) ?? 0 ) + 1
    }

    func checkAndUpdateWithKey(_ tableViewCell: InfoDetailTableViewCell, _ indexPath: IndexPath) {
        if let product = checkForProduct(with: tableViewCell.keyTextField.text ?? "") {
            if let infoProduct = DSData.shared.getInfoProduct(for: indexPath, in: infoSpreadsheet) {
                infoProduct.name = product.name
                infoProduct.cost = product.cost
                DSDataController.shared.saveProductContext()
            }
        }
    }

    fileprivate func updateTotalTextFields(_ indexPath: IndexPath) {
        if let infoProduct = DSData.shared.getInfoProduct(for: indexPath, in: infoSpreadsheet) {
            infoProduct.estimateTotal = Double(round(100 * Double(infoProduct.estimateQTY) * infoProduct.cost) / 100)
            infoProduct.asBuiltTotal = Double(round(100 * Double(infoProduct.asBuiltQTY) * infoProduct.cost) / 100)
            DSDataController.shared.saveProductContext()
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == 0 && indexPath.row == 0 {
            estimateTotal = 0
            actualTotal = 0
        }

        let sectionArray: [InfoProductSection] = infoSpreadsheet?.sections?.array as? [InfoProductSection] ?? []

        var tableViewCell = UITableViewCell()
        if sectionArray[indexPath.section].infoProducts?.count ?? 0 > indexPath.row {
            if let infoDetailTableViewCell =
                infoTableView.dequeueReusableCell(withIdentifier: "infoCell") as? InfoDetailTableViewCell {

                infoDetailTableViewCell.delegate = self
                infoDetailTableViewCell.addTableViewCellTextTargets()

                if let infoProduct: InfoProduct =
                    sectionArray[indexPath.section].infoProducts?[indexPath.row] as? InfoProduct {

                    infoDetailTableViewCell.keyTextField.text = infoProduct.id
                    checkAndUpdateWithKey(infoDetailTableViewCell, indexPath)
                    updateTotalTextFields(indexPath)

                    infoDetailTableViewCell.setInfoProduct(infoProduct: infoProduct)
                }

                infoDetailTableViewCell.setTableViewCellTextFieldTags()
                updateTotalLabels()

                return infoDetailTableViewCell
            }
        } else {
            tableViewCell = infoTableView.dequeueReusableCell(withIdentifier: "addCell")!
        }

        return tableViewCell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

// MARK: - TableView Actions
extension InfoDetailViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var sectionArray: [InfoProductSection] = infoSpreadsheet?.sections?.array as? [InfoProductSection] ?? []

        if sectionArray[indexPath.section].infoProducts?.count ?? (indexPath.row + 1) <= indexPath.row {
            let entity = NSEntityDescription.entity(forEntityName: "InfoProduct",
                                                    in: DSDataController.shared.viewContext)!
            let infoProduct = NSManagedObject(entity: entity,
                                              insertInto: DSDataController.shared.viewContext)
                                              as? InfoProduct ?? InfoProduct()
            infoProduct.setValue(0, forKey: "asBuiltQTY")
            infoProduct.setValue(0, forKey: "asBuiltTotal")
            infoProduct.setValue(0, forKey: "estimateQTY")
            infoProduct.setValue(0, forKey: "estimateTotal")

            sectionArray[indexPath.section].addToInfoProducts(infoProduct)
            DSDataController.shared.saveProductContext()
            infoTableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        let sectionArray: [InfoProductSection] = infoSpreadsheet?.sections?.array as? [InfoProductSection] ?? []
        if editingStyle == .delete {
            if let infoProduct = sectionArray[indexPath.section].infoProducts?[indexPath.row] as? InfoProduct {
                DSDataController.shared.viewContext.delete(infoProduct)
                DSDataController.shared.saveProductContext()
            }
            tableView.reloadData()
        }
    }
}

// MARK: - UI
extension InfoDetailViewController: UIPopoverPresentationControllerDelegate {
    @objc func showPopoutView() {
        if let pvc = self.storyboard?.instantiateViewController(withIdentifier: "detailInfoPopover")
                    as? InfoDetailPopoverViewController {

            pvc.parentVC = self
            pvc.modalPresentationStyle = .popover
            pvc.preferredContentSize = CGSize(width: 200, height: 200)

            let popover = pvc.popoverPresentationController
            popover?.delegate = self as UIPopoverPresentationControllerDelegate
            popover?.barButtonItem = self.navigationItem.rightBarButtonItem

            present(pvc, animated: false, completion: nil)
        }
    }

    func showDeleteSectionPopoutView() {
        if let pvc = self.storyboard?.instantiateViewController(withIdentifier: "detailInfoDeleteSectionPopover")
            as? DeleteSectionPopoverViewController {

            pvc.modalPresentationStyle = .overCurrentContext
            pvc.modalTransitionStyle = .crossDissolve
            pvc.parentVC = self
            pvc.infoSpreadsheet = self.infoSpreadsheet!
            pvc.preferredContentSize = CGSize(width: 250, height: 450)

            present(pvc, animated: true, completion: nil)
        }
    }

    func setupUI() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Actions",
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(self.showPopoutView))

        if new {
            self.navigationItem.hidesBackButton = true
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Home",
                                                                    style: .plain,
                                                                    target: self,
                                                                    action: #selector(self.showHomeView))

        }
    }

    @objc func showHomeView() {
        navigationController?.popToRootViewController(animated: true)
    }
}

// MARK: - InfoDetailCellDelegate Delegation
extension InfoDetailViewController: InfoDetailCellDelegate {
    @objc func textFieldDidChange(textField: UITextField) {

        if let cell: UITableViewCell = textField.superview?.superview as? UITableViewCell,
            let table: UITableView = cell.superview as? UITableView {

            if let textFieldIndexPath = table.indexPath(for: cell) {
                if let infoProduct = DSData.shared.getInfoProduct(for: textFieldIndexPath, in: infoSpreadsheet) {
                    switch textField.tag {
                    case 1:
                        infoProduct.id = textField.text!
                    case 2:
                        infoProduct.name = textField.text!
                    case 3:
                        infoProduct.cost = Double(textField.text!) ?? 0
                    case 4:
                        infoProduct.estimateQTY = Int32(textField.text!) ?? 0
                    case 5:
                        infoProduct.estimateTotal = Double(textField.text!) ?? 0
                    case 6:
                        infoProduct.asBuiltQTY = Int32(textField.text!) ?? 0
                    case 7:
                        infoProduct.asBuiltTotal = Double(textField.text!) ?? 0
                    default:
                        print("Textfield Tag Not Found")
                    }
                    DSDataController.shared.saveProductContext()
                }
            }
        }

        updateTotalLabels()
    }

    @objc func textFieldEndEditing(textField: UITextField) {
        if let cell: UITableViewCell = textField.superview?.superview as? UITableViewCell,
            let table: UITableView = cell.superview as? UITableView {
            if let textFieldIndexPath = table.indexPath(for: cell) {
                if let infoProduct = DSData.shared.getInfoProduct(for: textFieldIndexPath, in: infoSpreadsheet) {

                    switch textField.tag {
                    case 1:
                        if let product = checkForProduct(with: textField.text!) {
                            infoProduct.name = product.name
                            infoProduct.cost = product.cost
                        }
                    case 3:
                        infoProduct.cost = Double(textField.text!) ?? 0
                    case 4:
                        infoProduct.estimateQTY = Int32(textField.text!) ?? 0
                    case 6:
                        infoProduct.asBuiltQTY = Int32(textField.text!) ?? 0
                    default:
                        print("TEXT FIELD DID END EDITING")
                    }

                    DSDataController.shared.saveProductContext()
                    infoTableView.reloadData()
                }
            }
        }
    }
}

// MARK: - Data Manipulation
extension InfoDetailViewController {
    func addSection() {
        let alert = UIAlertController(title: "Add New Section", message: nil, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Add", style: .default) { (_) in
            if let txtField = alert.textFields?.first, let text = txtField.text {
                let entity = NSEntityDescription.entity(forEntityName: "InfoProductSection",
                                                        in: DSDataController.shared.viewContext)!

                if let infoProductSection = NSManagedObject(entity: entity,
                                                            insertInto: DSDataController.shared.viewContext)
                                                            as? InfoProductSection {
                    infoProductSection.name = text
                    self.infoSpreadsheet?.addToSections(infoProductSection)
                    DSDataController.shared.saveProductContext()
                    self.infoTableView.reloadData()
                }
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        alert.addTextField { (textField) in
            textField.placeholder = "Section Name"
        }
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)

    }

    func editClientInfo() {
        if let infoViewController =
            storyboard?.instantiateViewController(withIdentifier: "infoViewController") as? InfoViewController {
            infoViewController.editingExisting = true
            infoViewController.infoSpreadsheet = self.infoSpreadsheet
            navigationController?.pushViewController(infoViewController, animated: true)
        }
    }

    func exportInfoData() {
        CSVFile.createCSVStringFromInfo(infoSpreadsheet: infoSpreadsheet!, curViewController: self)
    }

    func markAsCompleted() {
        infoSpreadsheet?.completed = !(infoSpreadsheet?.completed ?? true)
        DSDataController.shared.saveProductContext()
    }

    func checkForProduct(with key: String) -> Product? {
        DSData.shared.fetchProducts()
        for product in DSData.shared.products where product.id == key {
                return product
        }
        return nil
    }
}
