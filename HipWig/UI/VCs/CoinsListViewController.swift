//
//  CoinsListViewController.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 5/29/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit

private enum Section: Int, CaseIterable {
    case myCoins
    case oneTimePurpose
    case coinList
}

class CoinsListViewController: BaseViewController {
    
    //MARK: - IBOutlets -
    @IBOutlet private weak var tableView: UITableView!
    
    //MARK: - Properties -
    
    //MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.onLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    deinit {
        print(#file + " " + #function)
    }
    
    //MARK: - Private -
    private func onLoad() {
        self.setup(tableView: self.tableView)
        
        self.view.adjustConstraints() 
    }
    
    private func setup(tableView: UITableView) {
        tableView.registerNib(with: MyCoinsCell.self)
        tableView.registerNib(with: CoinDiscountPurposeCell.self)
        tableView.registerNib(with: CoinCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()
    }
    
    override func backDidSelect(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
}

extension CoinsListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == Section.oneTimePurpose.rawValue {
            let view = UIView()
            if let viewToPlce = CoinSeparatorView.fromXib() {
                view.place(viewToPlce)
            }
            
            return view
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == Section.oneTimePurpose.rawValue {
            return 10.0.adjusted
        } else {
            return 0.01
        }
    }
}

extension CoinsListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == Section.myCoins.rawValue {
            let cell: MyCoinsCell = tableView.dequeueReusableCell(indexPath: indexPath)
            
            return cell
        } else if indexPath.section == Section.oneTimePurpose.rawValue {
            let cell: CoinDiscountPurposeCell = tableView.dequeueReusableCell(indexPath: indexPath)
            
            return cell
        } else {
            let cell: CoinCell = tableView.dequeueReusableCell(indexPath: indexPath)
            
            return cell
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Section.myCoins.rawValue {
            return 1
        } else if section == Section.oneTimePurpose.rawValue {
            return 1
        } else {
            return 5
        }
    }
}
