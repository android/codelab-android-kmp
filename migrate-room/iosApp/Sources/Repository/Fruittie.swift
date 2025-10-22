//
//  Fruittie.swift
//  Fruitties
//
//  Created by Muhammad Shuja Reshi on 21/10/25.
//  Copyright © 2025 orgName. All rights reserved.
//

import sharedKit

struct Fruittie: Hashable {
   let entity: FruittieEntity

   var id: Int64 {
       entity.id
   }

   var name: String? {
       entity.name
   }

   var fullName: String? {
       entity.fullName
   }
}
