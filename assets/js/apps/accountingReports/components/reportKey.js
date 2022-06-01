import GeneralLedger from './generalLedger';
import MultiMonth from './multiMonth';
import BalanceReport from './balance';
import IncomeStatement from './income';
import BudgetComparison from './budget';

export default {
  income: IncomeStatement,
  balance: BalanceReport,
  t12: MultiMonth,
  gl: GeneralLedger,
  budget: BudgetComparison
}